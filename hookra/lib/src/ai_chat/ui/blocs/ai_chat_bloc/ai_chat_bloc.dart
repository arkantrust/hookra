import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/ai_chat/data/repos/hookra_chat_provider.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';

part 'ai_chat_event.dart';
part 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  AiChatBloc({
    required this._sendMessage,
    required this._contentId,
    required this._platform,
    required this._format,
    required this._title,
  }) : super(const AiChatInitial()) {
    on<AiChatStarted>(_onStarted);
  }

  final SendMessageUseCase _sendMessage;
  final String _contentId;
  final String _platform;
  final String _format;
  final String _title;

  void _onStarted(AiChatStarted event, Emitter<AiChatState> emit) {
    emit(
      AiChatReady(
        provider: HookraChatProvider(
          sendMessage: _sendMessage,
          contentId: _contentId,
          platform: _platform,
          format: _format,
          title: _title,
        ),
      ),
    );
  }
}
