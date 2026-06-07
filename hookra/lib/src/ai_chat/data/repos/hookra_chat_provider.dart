// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';

class HookraChatProvider extends LlmProvider with ChangeNotifier {
  HookraChatProvider({
    required SendMessageUseCase sendMessage,
    required this.orgId,
    required this.teamId,
  }) : _sendMessage = sendMessage;

  final SendMessageUseCase _sendMessage;
  final String orgId;
  final String teamId;

  final List<ChatMessage> _history = [];

  @override
  Iterable<ChatMessage> get history => List.unmodifiable(_history);

  @override
  set history(Iterable<ChatMessage> history) {
    _history
      ..clear()
      ..addAll(history);
    notifyListeners();
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) => _sendMessage(
    orgId: orgId,
    teamId: teamId,
    prompt: prompt,
    history: _toAgentHistory(_history),
  );

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) {
    final historyForApi = _toAgentHistory(_history);

    _history.add(ChatMessage.user(prompt, attachments));
    notifyListeners();

    final llmMessage = ChatMessage.llm();
    _history.add(llmMessage);
    notifyListeners();

    return _sendMessage(
      orgId: orgId,
      teamId: teamId,
      prompt: prompt,
      history: historyForApi,
    ).map((chunk) {
      llmMessage.append(chunk);
      notifyListeners();
      return chunk;
    });
  }

  List<AgentMessage> _toAgentHistory(List<ChatMessage> history) => history
      .where((m) => m.text != null && m.text!.isNotEmpty)
      .map(
        (m) => AgentMessage(
          role: m.origin == MessageOrigin.user
              ? AgentMessageRole.user
              : AgentMessageRole.agent,
          text: m.text!,
        ),
      )
      .toList();
}
