import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

/// Creates an organization and immediately adds the creator as owner.
/// Both steps are sequential; if addMember fails the org is already created
/// (see repository TODO for atomic RPC alternative).
class CreateOrganizationUseCase {
  final OrganizationRepository _repository;

  CreateOrganizationUseCase(this._repository);

  Future<Result<Organization>> call({
    required String name,
    required String ownerId,
  }) async {
    final orgResult = await _repository.createOrganization(name, ownerId);
    if (orgResult.isFailure) return orgResult;

    final addResult = await _repository.addMember(
      orgResult.value.id,
      ownerId,
      OrganizationRole.owner,
    );
    if (addResult.isFailure) return Result.failure(addResult.error);

    return orgResult;
  }
}
