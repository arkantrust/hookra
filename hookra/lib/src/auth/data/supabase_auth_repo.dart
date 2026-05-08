import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/auth/domain/failures/auth_failure.dart';
import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/network.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template supabase_auth_repository}
/// Repository which manages user auth through Supabase.
///
/// Wraps around the [SupabaseClient] and maps
/// Supabase exceptions to domain failures.
/// {@endtemplate}
final class SupabaseAuthRepository extends AuthRepository {
  final SupabaseClient _supabase;

  final _controller = StreamController<AuthStatus>();

  SupabaseAuthRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<Result> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName, 'last_name': lastName},
      );

      _controller.add(AuthStatus.authenticated);
      return const Result.voidResult();
    } on AuthWeakPasswordException {
      return Result.failure(const WeakPassword());
    } on AuthApiException catch (e) {
      if (e.code == 'user_already_exists') {
        return Result.failure(const EmailAlreadyExists());
      }
      rethrow;
    } on AuthRetryableFetchException {
      final connected = await hasInternetAccess();
      if (!connected) {
        return Result.failure(const NoInternetConnection());
      } else {
        return Result.failure(const ServerUnreachable());
      }
    } catch (e, s) {
      return Result.unknown(name: 'SupabaseAuthRepository', error: e, stackTrace: s);
    }
  }

  @override
  Future<Result> signIn({required String email, required String password}) async {
    try {
      final res = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (res.session == null) return Result.failure(const NoSessionFound());
      _controller.add(AuthStatus.authenticated);
      return const Result.voidResult();
    } on AuthApiException catch (e) {
      if (e.code == 'invalid_credentials') {
        final emailExistsRes =
            await _supabase.from('profiles').select().eq('email', email).maybeSingle();
        final exists = emailExistsRes?.isNotEmpty ?? false;
        return Result.failure(exists ? const WrongPassword() : const EmailNotFound());
      }
      rethrow;
    } on AuthRetryableFetchException {
      final connected = await hasInternetAccess();
      if (!connected) {
        return Result.failure(const NoInternetConnection());
      } else {
        return Result.failure(const ServerUnreachable());
      }
    } catch (e, s) {
      return Result.unknown(name: 'SupabaseAuthRepository', error: e, stackTrace: s);
    }
  }

  @override
  Future<Result> signOut() async {
    try {
      await _supabase.auth.signOut();
      _controller.add(AuthStatus.unauthenticated);
      return const Result.voidResult();
    } on AuthRetryableFetchException {
      final connected = await hasInternetAccess();
      if (!connected) {
        return Result.failure(const NoInternetConnection());
      } else {
        return Result.failure(const ServerUnreachable());
      }
    } catch (e, s) {
      return Result.unknown(name: 'SupabaseAuthRepository', error: e, stackTrace: s);
    }
  }

  // ---------------------------------------------------------------------------
  // Password recovery
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> sendPasswordReset(
    String email, {
    required String redirectTo,
  }) async {
    try {
      // Supabase never reveals whether the email exists — always returns 200.
      await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
      return const Result.voidResult();
    } on AuthRetryableFetchException {
      final connected = await hasInternetAccess();
      if (!connected) {
        return Result.failure(const NoInternetConnection());
      } else {
        return Result.failure(const ServerUnreachable());
      }
    } catch (e, s) {
      return Result.unknown(name: 'SupabaseAuthRepository.sendPasswordReset', error: e, stackTrace: s);
    }
  }

  @override
  Future<Result<void>> resetPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return const Result.voidResult();
    } on AuthApiException catch (e) {
      if (e.statusCode == '422' || e.code == 'token_expired') {
        return Result.failure(const InvalidOrExpiredToken());
      }
      return Result.failure(const PasswordResetFailed());
    } catch (e, s) {
      return Result.unknown(name: 'SupabaseAuthRepository.resetPassword', error: e, stackTrace: s);
    }
  }

  @override
  Future<Result<void>> resetPasswordWithAccessToken(
    String accessToken,
    String newPassword,
  ) async {
    try {
      final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
      final anonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
      if (supabaseUrl.isEmpty || anonKey.isEmpty) {
        return Result.failure(const PasswordResetFailed());
      }

      final uri = Uri.parse(supabaseUrl).replace(path: '/auth/v1/user');
      final httpClient = HttpClient();
      final request = await httpClient.patchUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('apikey', anonKey);
      request.headers.set('Authorization', 'Bearer $accessToken');
      request.write(jsonEncode({'password': newPassword}));
      final response = await request.close();
      await response.transform(utf8.decoder).join();
      httpClient.close(force: true);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Result.voidResult();
      }

      // 401 / 422 typically means token expired
      if (response.statusCode == 401 || response.statusCode == 422) {
        return Result.failure(const InvalidOrExpiredToken());
      }

      return Result.failure(PasswordResetFailed());
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseAuthRepository.resetPasswordWithAccessToken',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> exchangeRefreshToken(String refreshToken) async {
    try {
      final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
      final anonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
      if (supabaseUrl.isEmpty || anonKey.isEmpty) return null;

      final uri = Uri.parse(supabaseUrl).replace(path: '/auth/v1/token');
      final requestBody =
          'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(refreshToken)}';
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.headers.set('apikey', anonKey);
      request.write(requestBody);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      httpClient.close(force: true);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------

  @override
  Stream<AuthStatus> get status async* {
    yield AuthStatus.unknown;
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.initialSession) {
        _controller.add(AuthStatus.authenticated);
      } else if (event == AuthChangeEvent.signedOut) {
        _controller.add(AuthStatus.unauthenticated);
      }
    });
    yield* _controller.stream;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
