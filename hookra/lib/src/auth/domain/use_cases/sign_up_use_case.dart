import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template sign_up_use_case}
/// Creates a new user with [firstName], [lastName], [email] and [password].
/// {@endtemplate}
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Result<void>> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _repository.signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }
}
