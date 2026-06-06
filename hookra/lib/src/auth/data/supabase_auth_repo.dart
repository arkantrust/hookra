import 'dart:async';

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

  SupabaseAuthRepository({required this._supabase});

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
      return Result.unknown(
        name: 'SupabaseAuthRepository',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session == null) return Result.failure(const NoSessionFound());
      _controller.add(AuthStatus.authenticated);
      return const Result.voidResult();
    } on AuthApiException catch (e) {
      if (e.code == 'invalid_credentials') {
        final emailExistsRes = await _supabase
            .from('profiles')
            .select()
            .eq('email', email)
            .maybeSingle();
        final exists = emailExistsRes?.isNotEmpty ?? false;
        return Result.failure(
          exists ? const WrongPassword() : const EmailNotFound(),
        );
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
      return Result.unknown(
        name: 'SupabaseAuthRepository',
        error: e,
        stackTrace: s,
      );
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
      return Result.unknown(
        name: 'SupabaseAuthRepository',
        error: e,
        stackTrace: s,
      );
    }
  }

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
