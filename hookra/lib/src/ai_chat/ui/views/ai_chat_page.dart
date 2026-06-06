import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hookra/src/ai_chat/data/repos/hookra_chat_provider.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';
import 'package:hookra/src/ai_chat/ui/blocs/ai_chat_bloc/ai_chat_bloc.dart';
import 'package:hookra/src/config/service_locator.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({
    super.key,
    required this.contentId,
    required this.platform,
    required this.format,
    required this.title,
  });

  final String contentId;
  final String platform;
  final String format;
  final String title;

  static GoRoute route() {
    return GoRoute(
      path: '/content/:contentId/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>;
        return AiChatPage(
          contentId: state.pathParameters['contentId']!,
          platform: extra['platform']!,
          format: extra['format']!,
          title: extra['title']!,
        );
      },
    );
  }

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late final AiChatBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AiChatBloc(
      sendMessage: sl<SendMessageUseCase>(),
      contentId: widget.contentId,
      platform: widget.platform,
      format: widget.format,
      title: widget.title,
    )..add(const AiChatStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AiChatBloc, AiChatState>(
        builder: (context, state) {
          return switch (state) {
            AiChatInitial() => Scaffold(
                appBar: AppBar(title: const Text('Content Assistant')),
                body: const Center(child: CircularProgressIndicator()),
              ),
            AiChatError(:final failure) => Scaffold(
                appBar: AppBar(title: const Text('Content Assistant')),
                body: Center(child: Text('Error: $failure')),
              ),
            AiChatReady(:final provider) =>
              ChangeNotifierProvider<HookraChatProvider>.value(
                value: provider,
                child: Scaffold(
                  appBar: AppBar(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Content Assistant'),
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  body: LlmChatView(
                    provider: provider,
                    welcomeMessage:
                        "Hi! I'm your content assistant. Ready to generate "
                        'the script for your **${widget.format}** on '
                        '**${widget.platform}** — *"${widget.title}"*. '
                        'Describe the brief, tone, and goal.',
                    suggestions: _suggestionsFor(widget.platform),
                    enableAttachments: false,
                    enableVoiceNotes: false,
                    style: LlmChatViewStyle(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      userMessageStyle: UserMessageStyle(
                        textStyle: const TextStyle(color: Colors.white),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.zero,
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                      llmMessageStyle: LlmMessageStyle(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.zero,
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          };
        },
      ),
    );
  }

  static List<String> _suggestionsFor(String platform) => switch (platform) {
        'instagram' => [
            'Generate the script with a curiosity hook',
            'Create an emotional script that drives comments',
            'Make it funny with a CTA to follow the profile',
          ],
        'tiktok' => [
            'Script with a shock hook in the first 2 seconds',
            'TikTok storytelling trend format',
            'Question-answer-surprise format',
          ],
        'linkedin' => [
            'Thought leadership post with data',
            'Personal professional learning story',
            'Controversial opinion in my industry',
          ],
        'twitter' => [
            'Thread of 5 tweets with a strong hook',
            'Short high-impact tweet with a question',
          ],
        'youtube' => [
            'Script for a 60-second YouTube Short',
            'Hook intro + development + subscribe CTA',
          ],
        _ => [
            'Generate the script for this content',
            'Suggest a hook for this post',
          ],
      };
}
