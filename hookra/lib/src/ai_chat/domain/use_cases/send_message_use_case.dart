import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';
import 'package:hookra/src/ai_chat/domain/repos/agent_chat_repository.dart';

class SendMessageUseCase {
  SendMessageUseCase(this._repository);

  final AgentChatRepository _repository;

  Stream<String> call({
    required String orgId,
    required String teamId,
    required String prompt,
    required List<AgentMessage> history,
  }) => _repository.sendMessage(
        orgId: orgId,
        teamId: teamId,
        prompt: prompt,
        history: history,
      );
}
