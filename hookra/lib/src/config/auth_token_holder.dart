/// Short-lived in-memory holder for recovery tokens.
/// Tokens are stored only in memory and cleared after consumption.
class AuthTokenHolder {
  String? _accessToken;
  String? _refreshToken;

  AuthTokenHolder._internal();
  static final AuthTokenHolder instance = AuthTokenHolder._internal();

  void setTokens({required String accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Consume the access token (returns it and clears it from memory).
  String? consumeAccessToken() {
    final t = _accessToken;
    _accessToken = null;
    return t;
  }

  String? peekAccessToken() => _accessToken;

  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}
