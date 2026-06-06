import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/ai_chat/data/repos/hookra_chat_provider.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';

part 'ai_chat_event.dart';
part 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  AiChatBloc({
    required this._sendMessage,
    required this._orgId,
    required this._teamId,
  }) : super(const AiChatInitial()) {
    on<AiChatStarted>(_onStarted);
  }

  final SendMessageUseCase _sendMessage;
  final String _orgId;
  final String _teamId;

  void _onStarted(AiChatStarted event, Emitter<AiChatState> emit) {
    emit(
      AiChatReady(
        provider: HookraChatProvider(
          sendMessage: _sendMessage,
          orgId: _orgId,
          teamId: _teamId,
        ),
      ),
    );
  }
}
