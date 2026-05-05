import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_member.dart';
import 'package:hookra/features/organization_roles/ui/bloc/organization_roles_bloc.dart';

class OrganizationRolesScreen extends StatelessWidget {
  const OrganizationRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganizationRolesBloc, OrganizationRolesState>(
      listenWhen:
          (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Roles de la organización')),
        body: BlocBuilder<OrganizationRolesBloc, OrganizationRolesState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.members.isEmpty) {
              return const Center(child: Text('No hay miembros para mostrar'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.members.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final member = state.members[index];
                final isCurrentUser =
                    state.currentProfileId == member.profileId;
                final canEdit =
                    _canEditMemberRole(
                      actorRole: state.currentUserRole,
                      member: member,
                    ) &&
                    !state.isSaving;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(
                    '${member.email}\n${isCurrentUser ? "Tú" : "Miembro"}',
                  ),
                  trailing:
                      state.isSaving &&
                              state.updatingProfileId == member.profileId
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : DropdownButton<OrganizationRole>(
                            value: member.role,
                            items: OrganizationRole.values
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role.label),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged:
                                canEdit
                                    ? (newRole) {
                                      if (newRole == null ||
                                          newRole == member.role) {
                                        return;
                                      }
                                      context.read<OrganizationRolesBloc>().add(
                                        OrganizationMemberRoleChanged(
                                          memberProfileId: member.profileId,
                                          newRole: newRole,
                                        ),
                                      );
                                    }
                                    : null,
                          ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _canEditMemberRole({
    required OrganizationRole? actorRole,
    required OrganizationMember member,
  }) {
    if (actorRole == null) {
      return false;
    }
    return switch (actorRole) {
      OrganizationRole.owner => true,
      OrganizationRole.admin => member.role == OrganizationRole.member,
      OrganizationRole.member => false,
    };
  }
}
