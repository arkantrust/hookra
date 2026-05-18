import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

class UpdateMemberRoleUseCase {
  final OrganizationRepository _repository;

  UpdateMemberRoleUseCase(this._repository);

  Future<Result<void>> call({
    required String organizationId,
    required String profileId,
    required OrganizationRole newRole,
  }) {
    return _repository.updateMemberRole(organizationId, profileId, newRole);
  }
}
