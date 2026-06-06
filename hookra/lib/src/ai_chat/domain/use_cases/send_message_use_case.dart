import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';
import 'package:hookra/src/ai_chat/domain/repos/agent_chat_repository.dart';

class SendMessageUseCase {
  SendMessageUseCase(this._repository);

  final AgentChatRepository _repository;

  Stream<String> call({
    required String contentId,
    required String prompt,
    required List<AgentMessage> history,
    required String platform,
    required String format,
    required String title,
  }) => _repository.sendMessage(
    contentId: contentId,
    prompt: prompt,
    history: history,
    platform: platform,
    format: format,
    title: title,
  );
}
