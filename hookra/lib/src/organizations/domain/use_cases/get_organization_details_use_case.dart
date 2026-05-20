import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

class OrganizationDetails {
  final Organization organization;
  final List<MemberWithProfile> members;

  const OrganizationDetails({
    required this.organization,
    required this.members,
  });
}

/// Fetches an organization and its full member list in a single use case
/// so callers (BLoC) never hold the repository directly.
class GetOrganizationDetailsUseCase {
  final OrganizationRepository _repository;

  GetOrganizationDetailsUseCase(this._repository);

  Future<Result<OrganizationDetails>> call(String organizationId) async {
    final orgResult = await _repository.getOrganizationById(organizationId);
    if (orgResult.isFailure) return Result.failure(orgResult.error);

    final org = orgResult.value;
    if (org == null) {
      return Result.failure(
        Exception('Organization $organizationId not found'),
      );
    }

    final membersResult = await _repository.getOrganizationMembers(
      organizationId,
    );
    if (membersResult.isFailure) return Result.failure(membersResult.error);

    return Result.success(
      OrganizationDetails(organization: org, members: membersResult.value),
    );
  }
}
