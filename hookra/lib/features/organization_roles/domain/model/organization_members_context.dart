import 'package:hookra/features/organization_roles/domain/model/organization_member.dart';

class OrganizationMembersContext {
  final String organizationId;
  final String currentProfileId;
  final OrganizationRole currentUserRole;
  final List<OrganizationMember> members;

  const OrganizationMembersContext({
    required this.organizationId,
    required this.currentProfileId,
    required this.currentUserRole,
    required this.members,
  });
}
