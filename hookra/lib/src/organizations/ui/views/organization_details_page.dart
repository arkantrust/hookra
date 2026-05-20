import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/organizations/domain/auth/role_auth.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/ui/blocs/invite_bloc/invite_bloc.dart';
import 'package:hookra/src/organizations/ui/blocs/organization_members_bloc/organization_members_bloc.dart';
import 'package:hookra/src/organizations/ui/components/invite_link_dialog.dart';
import 'package:hookra/src/organizations/ui/components/invite_modal.dart';
import 'package:hookra/src/organizations/ui/components/role_picker.dart';

class OrganizationDetailsPage extends StatelessWidget {
  final String organizationId;

  const OrganizationDetailsPage({super.key, required this.organizationId});

  static GoRoute route() {
    return GoRoute(
      path: '/organizations/:id',
      builder: (context, state) => OrganizationDetailsPage(
        organizationId: state.pathParameters['id']!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<OrganizationMembersBloc>()..add(LoadMembers(organizationId)),
        ),
        BlocProvider(create: (_) => sl<InviteBloc>()),
      ],
      child: _OrganizationDetailsView(organizationId: organizationId),
    );
  }
}

class _OrganizationDetailsView extends StatefulWidget {
  final String organizationId;

  const _OrganizationDetailsView({required this.organizationId});

  @override
  State<_OrganizationDetailsView> createState() =>
      _OrganizationDetailsViewState();
}

class _OrganizationDetailsViewState extends State<_OrganizationDetailsView> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  final _roleAuth = const RoleAuthorization();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select(
      (AuthBloc bloc) => bloc.state.user.id,
    );

    return BlocListener<InviteBloc, InviteState>(
      listener: (context, state) {
        if (state.status == InviteStatus.success) {
          Navigator.pop(context); // cierra el modal
          showDialog(
            context: context,
            builder: (_) => InviteLinkDialog(inviteLink: state.inviteLink!),
          );
        } else if (state.status == InviteStatus.failure) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error al generar invitación')),
          );
        }
      },
      child: BlocConsumer<OrganizationMembersBloc, OrganizationMembersState>(
      listener: (context, state) {
        if (state.status == OrganizationMembersStatus.loaded &&
            state.organization != null &&
            _nameController.text.isEmpty) {
          _nameController.text = state.organization!.name;
        }
        if (state.status == OrganizationMembersStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
      },
      builder: (context, state) {
        if (state.status == OrganizationMembersStatus.loading ||
            state.status == OrganizationMembersStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Organization')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.organization == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Organization')),
            body: const Center(child: Text('Organization not found')),
          );
        }

        final currentUserRole =
            state.members
                .where((m) => m.profileId == currentUserId)
                .firstOrNull
                ?.role;

        final canEditName =
            currentUserRole == OrganizationRole.owner &&
            currentUserId.isNotEmpty;

        final canInvite =
            currentUserId.isNotEmpty &&
            (currentUserRole == OrganizationRole.owner ||
                currentUserRole == OrganizationRole.admin);

        return Scaffold(
          appBar: AppBar(
            title:
                _isEditing
                    ? TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Organization name',
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      autofocus: true,
                    )
                    : Text(state.organization!.name),
            actions: [
              if (!_isEditing && canInvite)
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Invitar miembro',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BlocProvider.value(
                      value: context.read<InviteBloc>(),
                      child: InviteModal(
                        organizationId: widget.organizationId,
                      ),
                    ),
                  ),
                ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _saveName(context),
                )
              else if (canEditName)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveName(context),
                          child: const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _nameController.text = state.organization!.name;
                            setState(() => _isEditing = false);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Members (${state.members.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child:
                    state.members.isEmpty
                        ? const Center(child: Text('No members yet'))
                        : ListView.builder(
                          itemCount: state.members.length,
                          itemBuilder: (context, index) {
                            final member = state.members[index];
                            final isCurrentUser =
                                member.profileId == currentUserId;

                            final canChangeRole =
                                currentUserId.isNotEmpty &&
                                currentUserRole != null &&
                                _roleAuth.canChangeRole(
                                  actorRole: currentUserRole,
                                  targetRole: member.role,
                                  targetProfileId: member.profileId,
                                  organization: state.organization!,
                                  currentUserId: currentUserId,
                                );

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  member.firstName.isNotEmpty
                                      ? member.firstName[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(
                                '${member.firstName} ${member.lastName}'.trim(),
                              ),
                              subtitle: Text(member.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RolePicker(
                                    role: member.role,
                                    isInteractive: canChangeRole,
                                    onRoleSelected: (newRole) {
                                      context.read<OrganizationMembersBloc>().add(
                                        UpdateMemberRole(
                                          organizationId: widget.organizationId,
                                          profileId: member.profileId,
                                          newRole: newRole,
                                        ),
                                      );
                                    },
                                  ),
                                  if (isCurrentUser)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(
                                        '(You)',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  void _saveName(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.read<OrganizationMembersBloc>().add(
      UpdateOrganizationName(
        organizationId: widget.organizationId,
        name: name,
      ),
    );
    setState(() => _isEditing = false);
  }
}
