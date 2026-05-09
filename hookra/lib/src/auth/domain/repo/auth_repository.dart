import 'dart:async';

import 'package:hookra/src/utils/result.dart';

/// Possible auth status of the user.
/// - [unknown]: The auth status is unknown.
/// - [authenticated]: The user is authenticated.
/// - [unauthenticated]: The user is not authenticated.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// {@template auth_repository}
/// Repository to manage user auth.
/// {@endtemplate}
abstract base class AuthRepository {
  /// Creates a new user with the provided [firstName], [lastName], [email] and [password].
  Future<Result<void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  /// Signs in with the provided [email] and [password].
  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  /// Signs out the current user
  Future<Result<void>> signOut();

  /// Stream of [AuthStatus] which will emit the current status when the auth state changes.
  Stream<AuthStatus> get status;

  void dispose();
}
