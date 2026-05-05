import 'package:hookra/features/organization_roles/data/repo/organization_roles_repo_impl.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_member.dart';
import 'package:hookra/features/organization_roles/domain/repo/organization_roles_repo.dart';

class UpdateMemberRoleUsecase {
  OrganizationRolesRepo repo = OrganizationRolesRepoImpl();

  Future<void> execute({
    required String organizationId,
    required String actorProfileId,
    required OrganizationRole actorRole,
    required OrganizationMember targetMember,
    required OrganizationRole newRole,
  }) async {
    if (actorProfileId.isEmpty) {
      throw StateError('Usuario actual inválido');
    }

    if (targetMember.role == newRole) {
      return;
    }

    if (actorRole == OrganizationRole.member) {
      throw StateError('No tienes permisos para cambiar roles');
    }

    if (actorRole == OrganizationRole.admin &&
        targetMember.role != OrganizationRole.member) {
      throw StateError('Un admin solo puede cambiar roles de miembros');
    }

    await repo.updateMemberRole(
      organizationId: organizationId,
      profileId: targetMember.profileId,
      role: newRole,
    );
  }
}
