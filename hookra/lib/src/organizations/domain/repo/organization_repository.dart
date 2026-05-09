import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';

abstract class OrganizationRepository {
  Future<List<OrganizationMember>> getMembers(String organizationId);
  Future<Organization?> getOrganization(String organizationId);
  Future<OrganizationMember?> getMemberRole(
      String organizationId, String profileId);
  Future<void> updateMemberRole(String memberId, OrgRole newRole);
  Future<Organization?> getUserOrganization(String profileId);
  Future<List<Organization>> getUserOrganizations(String profileId);
}