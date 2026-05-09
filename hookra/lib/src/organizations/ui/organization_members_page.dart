import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/auth/can_change_role.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/organizations/ui/bloc/organization_members_bloc.dart';
import 'package:hookra/src/organizations/ui/widgets/role_pill.dart';

class OrganizationMembersPage extends StatelessWidget {
  final String organizationId;
  final String currentUserProfileId;

  const OrganizationMembersPage({
    super.key,
    required this.organizationId,
    required this.currentUserProfileId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationMembersBloc, OrganizationMembersState>(
      builder: (context, state) {
        if (state.status == OrganizationMembersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == OrganizationMembersStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.error ?? 'Error al cargar miembros'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<OrganizationMembersBloc>().add(
                          LoadOrganizationMembers(organizationId),
                        );
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final currentUserRole = state.members
            .where((m) => m.profileId == currentUserProfileId)
            .firstOrNull
            ?.role;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.members.length,
          itemBuilder: (context, index) {
            final member = state.members[index];
            final organization = state.organization;

            final canChange = organization != null &&
                currentUserRole != null &&
                canChangeRole(
                  actorRole: currentUserRole,
                  targetRole: member.role,
                  targetProfileId: member.profileId,
                  organizationOwnerId: organization.ownerId,
                );

            final isUpdating =
                state.updatingMemberId == member.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    member.profile != null
                        ? '${member.profile!.firstName[0]}${member.profile!.lastName[0]}'
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  member.profile != null
                      ? '${member.profile!.firstName} ${member.profile!.lastName}'
                      : 'Unknown',
                ),
                subtitle: Text(
                  member.profile?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: RolePill(
                  role: member.role,
                  canChange: canChange,
                  isUpdating: isUpdating,
                  onRoleChanged: (newRole) {
                    context.read<OrganizationMembersBloc>().add(
                          UpdateMemberRole(
                            memberId: member.id,
                            newRole: newRole,
                          ),
                        );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}