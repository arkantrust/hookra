part of 'ai_chat_bloc.dart';

sealed class AiChatState extends Equatable {
  const AiChatState();

  @override
  List<Object?> get props => [];
}

final class AiChatInitial extends AiChatState {
  const AiChatInitial();
}

final class AiChatReady extends AiChatState {
  const AiChatReady({required this.provider});
  final HookraChatProvider provider;

  @override
  List<Object?> get props => [provider];
}

final class AiChatError extends AiChatState {
  const AiChatError({required this.failure});
  final Exception failure;

  @override
  List<Object?> get props => [failure];
}
