import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetOrganizationsUseCase {
  final OrganizationRepository _repository;

  GetOrganizationsUseCase(this._repository);

  Future<Result<List<OrganizationWithRole>>> call() {
    return _repository.getOrganizationsForCurrentUser();
  }
}
