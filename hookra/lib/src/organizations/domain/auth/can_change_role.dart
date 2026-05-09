import 'package:hookra/src/organizations/domain/model/role.dart';

bool canChangeRole({
  required OrgRole actorRole,
  required OrgRole targetRole,
  required String targetProfileId,
  required String organizationOwnerId,
}) {
  if (actorRole == OrgRole.member) {
    return false;
  }

  if (actorRole == OrgRole.admin) {
    return targetRole == OrgRole.member;
  }

  if (actorRole == OrgRole.owner) {
    if (targetRole == OrgRole.owner && targetProfileId == organizationOwnerId) {
      return false;
    }
    return true;
  }

  return false;
}