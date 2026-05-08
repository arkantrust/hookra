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
  Future<Result<void>> signIn({required String email, required String password});

  /// Signs out the current user
  Future<Result<void>> signOut();

  /// Sends a password recovery email to [email].
  /// Always resolves successfully to prevent user enumeration.
  Future<Result<void>> sendPasswordReset(
    String email, {
    required String redirectTo,
  });

  /// Updates the current user's password using the active SDK recovery session.
  Future<Result<void>> resetPassword(String newPassword);

  /// Updates the password via a REST call using an explicit [accessToken] from
  /// the recovery deep link. Used when the SDK session is not automatically
  /// restored (common on Android).
  Future<Result<void>> resetPasswordWithAccessToken(
    String accessToken,
    String newPassword,
  );

  /// Exchanges a [refreshToken] for a fresh session via Supabase REST.
  /// Returns the decoded JSON response or null on failure.
  Future<Map<String, dynamic>?> exchangeRefreshToken(String refreshToken);

  /// Stream of [AuthStatus] which will emit the current status when the auth state changes.
  Stream<AuthStatus> get status;

  void dispose();
}
