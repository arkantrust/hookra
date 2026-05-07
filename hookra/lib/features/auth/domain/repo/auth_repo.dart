abstract class AuthRepo {
  Future<String> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  );
  Future<void> login(String email, String password);
  /// Sends a password recovery email. Always succeed (no enumeration).
  Future<void> sendPasswordReset(String email, {required String redirectTo});

  /// Reset password when the user has a valid recovery session.
  /// Returns when password updated or throws if token invalid/expired.
  Future<void> resetPassword(String newPassword);
  /// Exchange a refresh token for a session/result map.
  Future<Map<String, dynamic>?> exchangeRefreshToken(String refreshToken);

  /// Update password using an access token obtained from the recovery link.
  Future<void> resetPasswordWithAccessToken(String accessToken, String newPassword);
}
