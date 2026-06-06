import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';

abstract base class AgentChatRepository {
  Stream<String> sendMessage({
    required String orgId,
    required String teamId,
    required String prompt,
    required List<AgentMessage> history,
  });

  void dispose();
}
