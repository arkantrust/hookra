import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// Update password by calling Supabase REST `/auth/v1/user` using an
  /// access token received from the recovery link. This does not rely on
  /// client-side SDK session restoration and is useful when the SDK session
  /// is not automatically available (common on Android when fragments are lost).
  Future<void> updatePasswordWithAccessToken(String accessToken, String password) async {
    final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
    if (supabaseUrl.isEmpty || anonKey.isEmpty) throw Exception('Supabase config missing');

    final uri = Uri.parse(supabaseUrl).replace(path: '/auth/v1/user');
    final httpClient = HttpClient();
    final request = await httpClient.patchUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', anonKey);
    request.headers.set('Authorization', 'Bearer $accessToken');
    request.write(jsonEncode({'password': password}));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    httpClient.close(force: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update password: ${response.statusCode} ${responseBody}');
    }
  }

  /// Exchange a refresh token for a session via Supabase REST `/auth/v1/token`.
  /// Returns decoded JSON (access_token, refresh_token, user, etc) or null on failure.
  Future<Map<String, dynamic>?> exchangeRefreshToken(String refreshToken) async {
    try {
      final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
      final anonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
      if (supabaseUrl.isEmpty || anonKey.isEmpty) return null;

      final uri = Uri.parse(supabaseUrl).replace(path: '/auth/v1/token');
      final body = 'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(refreshToken)}';
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.headers.set('apikey', anonKey);
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      httpClient.close(force: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json;
      }
    } catch (_) {}
    return null;
  }
}
