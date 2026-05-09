import 'package:hookra/src/auth/domain/repo/auth_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template sign_out_use_case}
/// Signs the current user out.
/// {@endtemplate}
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Result<void>> call() => _repository.signOut();
}
