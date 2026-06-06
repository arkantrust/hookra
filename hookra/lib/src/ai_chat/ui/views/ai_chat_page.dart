import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hookra/src/ai_chat/data/repos/hookra_chat_provider.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';
import 'package:hookra/src/ai_chat/ui/blocs/ai_chat_bloc/ai_chat_bloc.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/selection/selection.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  static GoRoute route() {
    return GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatPage(),
    );
  }

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  AiChatBloc? _bloc;
  String? _orgId;
  String? _teamId;

  @override
  void initState() {
    super.initState();
    final selection = context.read<SelectionCubit>().state;
    _orgId = selection.selectedOrgId;
    _teamId = selection.selectedTeamId;

    if (_orgId != null && _teamId != null) {
      _bloc = AiChatBloc(
        sendMessage: sl<SendMessageUseCase>(),
        orgId: _orgId!,
        teamId: _teamId!,
      )..add(const AiChatStarted());
    }
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_orgId == null || _teamId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Content Assistant')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Select an organization and team to start chatting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Go to Profile'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _bloc!,
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
                  appBar: AppBar(title: const Text('Content Assistant')),
                  body: LlmChatView(
                    provider: provider,
                    welcomeMessage:
                        "Hi! I'm your content assistant. Tell me what you "
                        'want to create — describe the platform, format, and topic.',
                    suggestions: const [
                      'Create an Instagram Reel',
                      'Write a LinkedIn post',
                      'Generate a TikTok script',
                      'Draft a YouTube Short',
                    ],
                    enableAttachments: false,
                    enableVoiceNotes: false,
                    style: LlmChatViewStyle(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
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
}
