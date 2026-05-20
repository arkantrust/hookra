import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/utils/result.dart';

class CreateInviteUseCase {
  final InviteRepository _repo;
  const CreateInviteUseCase(this._repo);

  Future<Result<OrgInvite>> call({
    required String organizationId,
    required String email,
    required OrganizationRole role,
  }) => _repo.createInvite(organizationId, email, role);
}
