import 'package:hookra/features/auth/domain/repo/auth_repo.dart';
import 'package:hookra/features/auth/data/repo/auth_repo_impl.dart';
import 'package:hookra/features/profile/domain/model/profile.dart';
import 'package:hookra/features/profile/domain/repo/profile_repository.dart';
import 'package:hookra/features/profile/data/repo/profile_repository_impl.dart';

class SignupUsecase {
  AuthRepo authRepo = AuthRepoImpl();
  ProfileRepository profileRepo = ProfileRepositoryImpl();

  Future<void> execute(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final userId = await authRepo.signup(email, password, firstName, lastName);
    await profileRepo.saveProfile(
      Profile(id: userId, firstName: firstName, lastName: lastName, email: email),
    );
  }
}
