import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const LLM_API_KEY = Deno.env.get('LLM_API_KEY')!;
const LLM_API_URL =
  Deno.env.get('LLM_API_URL') ?? 'https://api.groq.com/openai/v1/chat/completions';
const LLM_MODEL = Deno.env.get('LLM_MODEL') ?? 'llama-3.3-70b-versatile';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

function buildSystemPrompt(platform: string, format: string, title: string) {
  return `You are an expert social media content creator working inside Hookra.

Your task is to generate a structured script for the following content piece:
- Platform: ${platform}
- Format: ${format}
- Title: ${title}

Your process:
1. Confirm you understood the brief (1 line of feedback).
2. Generate the structured content internally.
3. At the end, return ONLY a JSON block with this exact structure:
   {"hook":"...","script":"...","caption":"...","cta":"...","hashtags":["...","..."]}

Content rules:
- Hook: max 2 sentences, captures attention in the first 3 seconds.
- Script: adapted to platform/format. For reels/tiktok max 150 words.
- Caption: post text, include relevant emojis.
- CTA: clear and specific.
- Hashtags: 5-15, mix of popularity levels.

Send ONLY brief feedback lines to the chat while working.
End your response with ---JSON--- followed by the JSON block on a new line.`;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }
  const jwt = authHeader.substring(7);

  const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response('Unauthorized', { status: 401 });
  }

  const body = await req.json();
  const { content_id, prompt, history, platform, format, title } = body;

  if (!content_id || !prompt || !platform || !format || !title) {
    return new Response('Bad Request: missing required fields', { status: 400 });
  }

  // Verify content access via user-scoped client (respects RLS)
  const { data: content, error: contentError } = await userClient
    .from('content')
    .select('id')
    .eq('id', content_id)
    .single();

  if (contentError || !content) {
    return new Response('Content not found', { status: 404 });
  }

  const messages = [
    { role: 'system', content: buildSystemPrompt(platform, format, title) },
    ...(history ?? []).map((m: { role: string; text: string }) => ({
      role: m.role === 'user' ? 'user' : 'assistant',
      content: m.text,
    })),
    { role: 'user', content: prompt },
  ];

  const llmResponse = await fetch(LLM_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LLM_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model: LLM_MODEL, messages, stream: true }),
  });

  if (!llmResponse.ok) {
    const errText = await llmResponse.text();
    console.error('LLM error:', llmResponse.status, errText);
    return new Response('LLM error', { status: 502 });
  }

  const encoder = new TextEncoder();
  let fullResponse = '';

  const stream = new ReadableStream({
    async start(controller) {
      const reader = llmResponse.body!.getReader();
      const decoder = new TextDecoder();

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          const text = decoder.decode(value);
          for (const line of text.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            const data = line.slice(6).trim();
            if (!data || data === '[DONE]') continue;
            try {
              const chunk =
                JSON.parse(data).choices?.[0]?.delta?.content ?? '';
              if (!chunk) continue;
              fullResponse += chunk;
              // Stream only feedback text (before the ---JSON--- separator)
              if (!fullResponse.includes('---JSON---')) {
                controller.enqueue(encoder.encode(`data: ${chunk}\n\n`));
              }
            } catch {
              // skip malformed SSE lines
            }
          }
        }
      } finally {
        reader.releaseLock();
      }

      // Parse and persist structured output
      const separatorIndex = fullResponse.indexOf('---JSON---');
      if (separatorIndex !== -1) {
        try {
          const jsonBlock = fullResponse.slice(separatorIndex + 10).trim();
          const structured = JSON.parse(jsonBlock);
          const serviceClient = createClient(
            SUPABASE_URL,
            SUPABASE_SERVICE_ROLE_KEY,
          );
          const { error: updateError } = await serviceClient
            .from('content')
            .update({
              hook: structured.hook,
              script: structured.script,
              caption: structured.caption,
              cta: structured.cta,
              hashtags: structured.hashtags,
              ai_model: LLM_MODEL,
              ai_prompt: prompt,
            })
            .eq('id', content_id);

          if (updateError) {
            console.error('DB update error:', updateError);
            controller.enqueue(
              encoder.encode(`data: ⚠ Could not save script: ${updateError.message}\n\n`),
            );
          } else {
            controller.enqueue(
              encoder.encode('data: ✓ Script saved successfully.\n\n'),
            );
          }
        } catch (e) {
          console.error('Parse/update error:', e);
          controller.enqueue(
            encoder.encode(`data: ⚠ Could not save script: ${e}\n\n`),
          );
        }
      } else {
        controller.enqueue(
          encoder.encode('data: ⚠ No structured script found in response.\n\n'),
        );
      }

      controller.enqueue(encoder.encode('data: [DONE]\n\n'));
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
});
