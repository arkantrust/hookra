import 'package:hookra/features/auth/domain/repo/auth_repo.dart';
import 'package:hookra/features/auth/data/repo/auth_repo_impl.dart';

class LoginUsecase {
  AuthRepo repo = AuthRepoImpl();

  Future<void> execute(String email, String password) async {
    await repo.login(email, password);
  }
}
