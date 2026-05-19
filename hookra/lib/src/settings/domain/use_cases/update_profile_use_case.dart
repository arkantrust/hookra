import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/profile/domain/repo/user_repository.dart';
import 'package:hookra/src/utils/result.dart';

class UpdateProfileUseCase {
  final UserRepository _repo;

  UpdateProfileUseCase(this._repo);

  Future<Result<User>> call({
    required String firstName,
    required String lastName,
  }) => _repo.updateUser(firstName: firstName, lastName: lastName);
}
