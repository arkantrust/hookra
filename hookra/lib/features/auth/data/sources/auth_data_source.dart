import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDataSource {
  Future<AuthResponse> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName, 'last_name': lastName},
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Request password recovery email. Provide `redirectTo` to ensure
  /// the verification link returns into the mobile app (deep link).
  Future<void> sendPasswordReset(String email, {required String redirectTo}) async {
    // supabase.auth.resetPasswordForEmail will not reveal whether the
    // email exists; it always returns success for security.
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  /// Update the user's password. This expects that the recovery link
  /// has already been used to restore a session in the app (implicit flow).
  Future<void> updatePassword(String password) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: password),
    );
  }
}
