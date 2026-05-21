import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/utils/result.dart';

class AcceptInviteUseCase {
  final InviteRepository _repo;
  const AcceptInviteUseCase(this._repo);

  Future<Result<void>> call(String token) => _repo.acceptInvite(token);
}
