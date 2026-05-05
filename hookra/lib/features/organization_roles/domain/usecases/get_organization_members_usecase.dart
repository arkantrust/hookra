import 'package:hookra/features/organization_roles/data/repo/organization_roles_repo_impl.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_members_context.dart';
import 'package:hookra/features/organization_roles/domain/repo/organization_roles_repo.dart';

class GetOrganizationMembersUsecase {
  OrganizationRolesRepo repo = OrganizationRolesRepoImpl();

  Future<OrganizationMembersContext> execute() async {
    return await repo.getMembersForCurrentUser();
  }
}
