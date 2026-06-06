part of 'ai_chat_bloc.dart';

sealed class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

final class AiChatStarted extends AiChatEvent {
  const AiChatStarted();
}
