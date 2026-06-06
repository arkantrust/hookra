import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';

abstract base class AgentChatRepository {
  Stream<String> sendMessage({
    required String contentId,
    required String prompt,
    required List<AgentMessage> history,
    required String platform,
    required String format,
    required String title,
  });

  void dispose();
}
