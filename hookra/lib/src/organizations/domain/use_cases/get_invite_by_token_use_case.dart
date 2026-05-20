import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetInviteByTokenUseCase {
  final InviteRepository _repo;
  const GetInviteByTokenUseCase(this._repo);

  Future<Result<OrgInvite>> call(String token) => _repo.getInviteByToken(token);
}
