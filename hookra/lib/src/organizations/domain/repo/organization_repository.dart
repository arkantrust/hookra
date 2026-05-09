import '../model/organization.dart';
import '../model/organization_member.dart';
import '../model/organization_with_role.dart';

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
  Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser();
  Future<Organization> createOrganization(String name, String ownerId);
  Future<void> addMember(String organizationId, String profileId, String role);
  Future<String> generateUniqueSlug(String baseName);
  Future<Organization?> getOrganizationById(String organizationId);
  Future<void> updateOrganizationName(String organizationId, String name);
  Future<List<MemberWithProfile>> getOrganizationMembers(String organizationId);
  Future<void> updateMemberRole(
    String organizationId,
    String profileId,
    OrganizationRole newRole,
  );
}
