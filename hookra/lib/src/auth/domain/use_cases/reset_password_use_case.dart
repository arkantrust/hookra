import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template reset_password_use_case}
/// Resets the current user's password using the active SDK recovery session.
/// {@endtemplate}
class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<Result<void>> call(String newPassword) {
    return _repository.resetPassword(newPassword);
  }
}
