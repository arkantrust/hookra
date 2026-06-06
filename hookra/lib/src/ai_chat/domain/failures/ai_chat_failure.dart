class AiChatNetworkFailure implements Exception {
  const AiChatNetworkFailure();
}

class AiChatAuthFailure implements Exception {
  const AiChatAuthFailure();
}

class AiChatContentNotFoundFailure implements Exception {
  const AiChatContentNotFoundFailure();
}

class AiChatUnknownFailure implements Exception {
  const AiChatUnknownFailure(this.message);
  final String message;
}
