import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';

class MemberWithProfile {
  final String profileId;
  final String firstName;
  final String lastName;
  final String email;
  final OrganizationRole role;

  MemberWithProfile({
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });
}

abstract class OrganizationRepository {
  // Role management methods
  Future<List<OrganizationMember>> getMembers(String organizationId);
  Future<Organization?> getOrganization(String organizationId);
  Future<OrganizationMember?> getMemberRole(
      String organizationId, String profileId);
  Future<void> updateMemberRole(String memberId, OrgRole newRole);
  Future<Organization?> getUserOrganization(String profileId);
  Future<List<Organization>> getUserOrganizations(String profileId);

  // Organization CRUD methods
  Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser();
  Future<Organization> createOrganization(String name, String ownerId);
  Future<void> addMember(String organizationId, String profileId, String role);
  Future<String> generateUniqueSlug(String baseName);
  Future<Organization?> getOrganizationById(String organizationId);
  Future<void> updateOrganizationName(String organizationId, String name);
  Future<List<MemberWithProfile>> getOrganizationMembers(String organizationId);
}