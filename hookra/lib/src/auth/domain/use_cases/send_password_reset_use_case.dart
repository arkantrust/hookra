import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template send_password_reset_use_case}
/// Sends a password recovery email to [email].
/// Always reports success to prevent user enumeration.
/// {@endtemplate}
class SendPasswordResetUseCase {
  final AuthRepository _repository;

  SendPasswordResetUseCase(this._repository);

  Future<Result<void>> call({
    required String email,
    required String redirectTo,
  }) {
    return _repository.sendPasswordReset(email, redirectTo: redirectTo);
  }
}
