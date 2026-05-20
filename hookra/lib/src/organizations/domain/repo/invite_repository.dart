import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/org_invite_details.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/utils/result.dart';

abstract class InviteRepository {
  Future<Result<OrgInvite>> createInvite(
    String organizationId,
    String email,
    OrganizationRole role,
  );
  Future<Result<OrgInviteDetails>> getInviteByToken(String token);
  Future<Result<void>> acceptInvite(String token);
  Future<void> dispose();
}
