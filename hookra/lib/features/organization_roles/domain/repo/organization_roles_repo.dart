import 'package:hookra/features/organization_roles/domain/model/organization_member.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_members_context.dart';

abstract class OrganizationRolesRepo {
  Future<OrganizationMembersContext> getMembersForCurrentUser();

  Future<void> updateMemberRole({
    required String organizationId,
    required String profileId,
    required OrganizationRole role,
  });
}
