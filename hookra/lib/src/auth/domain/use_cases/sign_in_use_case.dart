import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template sign_in_use_case}
/// Signs the user in with the provided [email] and [password].
/// {@endtemplate}
class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<Result<void>> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}
