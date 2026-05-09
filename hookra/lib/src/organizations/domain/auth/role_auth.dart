import '../model/organization.dart';
import '../model/organization_member.dart';

class RoleAuthorization {
  const RoleAuthorization();

  bool canChangeRole({
    required OrganizationRole actorRole,
    required OrganizationRole targetRole,
    required String targetProfileId,
    required Organization organization,
    required String currentUserId,
  }) {
    if (targetProfileId == currentUserId) {
      return false;
    }

    final isTargetSuperowner = organization.ownerId == targetProfileId;
    if (isTargetSuperowner) {
      return false;
    }

    switch (actorRole) {
      case OrganizationRole.owner:
        return true;
      case OrganizationRole.admin:
        return targetRole == OrganizationRole.member;
      case OrganizationRole.member:
        return false;
    }
  }
}
