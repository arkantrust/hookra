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
}
