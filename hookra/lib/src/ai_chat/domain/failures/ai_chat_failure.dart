class AiChatNetworkFailure implements Exception {
  const AiChatNetworkFailure();
  @override
  String toString() => 'Network error. Check your connection and try again.';
}

class AiChatAuthFailure implements Exception {
  const AiChatAuthFailure();
  @override
  String toString() => 'Authentication error. Please sign in again.';
}

class AiChatContentNotFoundFailure implements Exception {
  const AiChatContentNotFoundFailure();
  @override
  String toString() => 'Content not found.';
}

class AiChatUnknownFailure implements Exception {
  const AiChatUnknownFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
