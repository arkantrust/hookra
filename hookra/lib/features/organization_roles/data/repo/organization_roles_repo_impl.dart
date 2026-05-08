import 'dart:developer' as developer;

import 'package:hookra/features/organization_roles/data/sources/organization_roles_data_source.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_member.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_members_context.dart';
import 'package:hookra/features/organization_roles/domain/repo/organization_roles_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationRolesRepoImpl extends OrganizationRolesRepo {
  final OrganizationRolesDataSource _source = OrganizationRolesDataSource();

  @override
  Future<OrganizationMembersContext> getMembersForCurrentUser() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('Usuario no autenticado');
    }

    final currentMembership = await _source.getCurrentMembership(
      currentUser.id,
    );
    final organizationId =
        (currentMembership['organization_id'] ?? '').toString();
    if (organizationId.isEmpty) {
      throw StateError('No se encontró organización para el usuario actual');
    }

    final currentRole = OrganizationRoleMapper.fromDatabase(
      (currentMembership['role'] ?? 'member').toString(),
    );

    final memberRows = await _source.getOrganizationMembersRows(organizationId);
    final profileIds = memberRows
        .map((member) => (member['profile_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    // Intenta obtener perfiles, pero si falla por RLS, usa fallback
    Map<String, Map<String, dynamic>> profilesById = {};
    try {
      profilesById = await _source.getProfilesByIds(profileIds);
    } catch (e) {
      developer.log('Warning: Could not fetch profiles, using fallback: $e');
      // Fallback: los miembros mostrarán UUID como nombre
    }

    final members =
        memberRows.map((member) {
            final profileId = (member['profile_id'] ?? '').toString();
            final profile =
                profilesById[profileId] ?? const <String, dynamic>{};
            return OrganizationMember(
              organizationId: organizationId,
              profileId: profileId,
              role: OrganizationRoleMapper.fromDatabase(
                (member['role'] ?? 'member').toString(),
              ),
              firstName: (profile['first_name'] ?? '').toString(),
              lastName: (profile['last_name'] ?? '').toString(),
              email: (profile['email'] ?? '').toString(),
            );
          }).toList()
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

    return OrganizationMembersContext(
      organizationId: organizationId,
      currentProfileId: currentUser.id,
      currentUserRole: currentRole,
      members: members,
    );
  }

  @override
  Future<void> updateMemberRole({
    required String organizationId,
    required String profileId,
    required OrganizationRole role,
  }) async {
    await _source.updateMemberRole(
      organizationId: organizationId,
      profileId: profileId,
      role: role.databaseValue,
    );
  }
}
