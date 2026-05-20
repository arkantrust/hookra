import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

class UpdateOrganizationNameUseCase {
  final OrganizationRepository _repository;

  UpdateOrganizationNameUseCase(this._repository);

  Future<Result<void>> call({
    required String organizationId,
    required String name,
  }) {
    return _repository.updateOrganizationName(organizationId, name);
  }
}
