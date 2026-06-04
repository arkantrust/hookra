import 'package:hookra/src/utils/result.dart';

import '../model/member_with_profile.dart';
import '../model/organization.dart';
import '../model/organization_member.dart';
import '../model/organization_with_role.dart';

export '../model/member_with_profile.dart';

abstract class OrganizationRepository {
  Future<Result<List<OrganizationWithRole>>> getOrganizationsForCurrentUser();
  Future<Result<Organization>> createOrganization(String name, String ownerId);
  Future<Result<void>> addMember(
    String organizationId,
    String profileId,
    OrganizationRole role,
  );
  Future<Result<Organization?>> getOrganizationById(String organizationId);
  Future<Result<void>> updateOrganizationName(
    String organizationId,
    String name,
  );
  Future<Result<List<MemberWithProfile>>> getOrganizationMembers(
    String organizationId,
  );
  Future<Result<void>> updateMemberRole(
    String organizationId,
    String profileId,
    OrganizationRole newRole,
  );
  Future<void> dispose();
}
