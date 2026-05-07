import 'package:hookra/features/auth/domain/repo/auth_repo.dart';
import 'package:hookra/features/auth/data/sources/auth_data_source.dart';

class AuthRepoImpl extends AuthRepo {
  final AuthDataSource _source = AuthDataSource();

  @override
  Future<String> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    final response = await _source.signup(email, password, firstName, lastName);
    return response.user!.id;
  }

  @override
  Future<void> login(String email, String password) async {
    await _source.login(email, password);
  }

  @override
  Future<void> sendPasswordReset(String email, {required String redirectTo}) async {
    await _source.sendPasswordReset(email, redirectTo: redirectTo);
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    await _source.updatePassword(newPassword);
  }
}
