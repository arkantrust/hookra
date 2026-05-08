import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template reset_password_with_token_use_case}
/// Resets the user's password using a raw access token from the recovery
/// deep link via a REST fallback. Used when the Supabase SDK session is not
/// automatically restored (common on Android).
/// {@endtemplate}
class ResetPasswordWithTokenUseCase {
  final AuthRepository _repository;

  ResetPasswordWithTokenUseCase(this._repository);

  Future<Result<void>> call({
    required String accessToken,
    required String newPassword,
  }) {
    return _repository.resetPasswordWithAccessToken(accessToken, newPassword);
  }
}
