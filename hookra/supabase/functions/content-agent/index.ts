import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const LLM_API_KEY = Deno.env.get('LLM_API_KEY')!;
const LLM_API_URL =
  Deno.env.get('LLM_API_URL') ??
  'https://api.groq.com/openai/v1/chat/completions';
const LLM_MODEL = Deno.env.get('LLM_MODEL') ?? 'llama-3.3-70b-versatile';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// SYSTEM_PROMPT defines the agent behavior and the exact output format saved to the DB.
// To change how the agent generates content, edit this constant and redeploy.
// Output is stored in the `content` table (fields: title, platform, format, hook, script, caption, cta, hashtags).
const SYSTEM_PROMPT = `You are an expert social media content creator working inside Hookra.

When the user gives you a brief, follow this exact process:
1. Confirm you understood the brief in 1 short line.
2. Determine the best platform and format for what the user described.
3. Generate the full structured content.
4. End your response with ---JSON--- followed immediately by the JSON object.

PLATFORM values (use exactly one): instagram, tiktok, facebook, linkedin, twitter, youtube
FORMAT values (use exactly one): reel, story, post, video, image, carousel, text

Field rules:
- title: max 60 characters, descriptive name for this content piece
- hook: 1-2 sentences only, written to capture attention in the first 3 seconds
- script: plain text adapted to the platform and format; max 150 words for reels/tiktok/shorts
- caption: post caption text including relevant emojis (no JSON, no markdown)
- cta: one clear, specific call to action sentence
- hashtags: array of strings WITHOUT the # symbol, 5 to 15 items, mix of broad and niche

While generating, send ONLY brief plain-text feedback lines to the chat (no JSON yet).

End your entire response with this exact separator and JSON on the next line:
---JSON---
{"title":"...","platform":"...","format":"...","hook":"...","script":"...","caption":"...","cta":"...","hashtags":["...","..."]}`;

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
  const { org_id, team_id, prompt, history } = body;

  if (!org_id || !team_id || !prompt) {
    return new Response('Bad Request: missing org_id, team_id, or prompt', {
      status: 400,
    });
  }

  // Verify user is a member of the team
  const { data: membership, error: memberError } = await userClient
    .from('team_members')
    .select('id')
    .eq('team_id', team_id)
    .eq('profile_id', user.id)
    .single();

  if (memberError || !membership) {
    return new Response('Forbidden: not a member of this team', {
      status: 403,
    });
  }

  // Get the first project for this team
  const { data: project, error: projectError } = await userClient
    .from('projects')
    .select('id')
    .eq('team_id', team_id)
    .limit(1)
    .single();

  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
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
      if (separatorIndex === -1) {
        controller.enqueue(
          encoder.encode(
            'data: ⚠ No structured output found in response.\n\n',
          ),
        );
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
        return;
      }

      if (projectError || !project) {
        controller.enqueue(
          encoder.encode(
            'data: ⚠ No projects found for this team. Create one first.\n\n',
          ),
        );
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
        return;
      }

      try {
        const jsonBlock = fullResponse.slice(separatorIndex + 10).trim();
        const structured = JSON.parse(jsonBlock);

        const serviceClient = createClient(
          SUPABASE_URL,
          SUPABASE_SERVICE_ROLE_KEY,
        );
        const { error: insertError } = await serviceClient
          .from('content')
          .insert({
            project_id: project.id,
            created_by: user.id,
            title: structured.title,
            platform: structured.platform,
            format: structured.format,
            hook: structured.hook,
            script: structured.script,
            caption: structured.caption,
            cta: structured.cta,
            hashtags: structured.hashtags,
            ai_model: LLM_MODEL,
            ai_prompt: prompt,
          });

        if (insertError) {
          console.error('DB insert error:', insertError);
          controller.enqueue(
            encoder.encode(
              `data: ⚠ Could not save content: ${insertError.message}\n\n`,
            ),
          );
        } else {
          controller.enqueue(
            encoder.encode('data: ✓ Content saved to your project.\n\n'),
          );
        }
      } catch (e) {
        console.error('Parse/insert error:', e);
        controller.enqueue(
          encoder.encode(`data: ⚠ Could not save content: ${e}\n\n`),
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
      Connection: 'keep-alive',
    },
  });
});
