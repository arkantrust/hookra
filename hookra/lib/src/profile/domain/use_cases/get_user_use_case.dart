import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/profile/domain/repo/user_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template get_user_use_case}
/// Returns the currently authenticated [User], if any.
/// {@endtemplate}
class GetUserUseCase {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  Future<Result<User>> call() => _repository.getUser();

  void dispose() => _repository.dispose();
}
