import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';

class HookraChatProvider extends LlmProvider with ChangeNotifier {
  HookraChatProvider({
    required SendMessageUseCase sendMessage,
    required this.contentId,
    required this.platform,
    required this.format,
    required this.title,
  }) : _sendMessage = sendMessage;

  final SendMessageUseCase _sendMessage;
  final String contentId;
  final String platform;
  final String format;
  final String title;

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
        contentId: contentId,
        prompt: prompt,
        history: _toAgentHistory(_history),
        platform: platform,
        format: format,
        title: title,
      );

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) {
    _history.add(ChatMessage.user(prompt, attachments));
    notifyListeners();

    // Snapshot history for API before adding the response placeholder
    final historyForApi = _toAgentHistory(_history);

    // Pre-create the LLM message so it appears immediately in the UI
    final llmMessage = ChatMessage.llm();
    _history.add(llmMessage);
    notifyListeners();

    return _sendMessage(
      contentId: contentId,
      prompt: prompt,
      history: historyForApi,
      platform: platform,
      format: format,
      title: title,
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
