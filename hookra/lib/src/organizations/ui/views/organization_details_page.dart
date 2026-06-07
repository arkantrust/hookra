import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/teams/teams.dart';
import 'package:hookra/src/config/service_locator.dart';

class OrganizationDetailsPage extends StatefulWidget {
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
  State<OrganizationDetailsPage> createState() =>
      _OrganizationDetailsPageState();
}

class _OrganizationDetailsPageState extends State<OrganizationDetailsPage> {
  late final OrganizationMembersBloc _membersBloc;
  late final TeamsBloc _teamsBloc;
  late final InviteBloc _inviteBloc;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  final _roleAuth = const RoleAuthorization();

  @override
  void initState() {
    super.initState();
    _membersBloc = OrganizationMembersBloc(
      getDetails: sl<GetOrganizationDetailsUseCase>(),
      updateMemberRole: sl<UpdateMemberRoleUseCase>(),
      updateOrgName: sl<UpdateOrganizationNameUseCase>(),
    );
    _membersBloc.add(LoadMembers(widget.organizationId));

    final currentUserId = sl<AuthBloc>().state.user.id;
    _teamsBloc = TeamsBloc(
      organizationId: widget.organizationId,
      creatorId: currentUserId,
      getTeams: sl<GetTeamsUseCase>(),
      createTeam: sl<CreateTeamUseCase>(),
      deleteTeam: sl<DeleteTeamUseCase>(),
      joinTeam: sl<JoinTeamUseCase>(),
      leaveTeam: sl<LeaveTeamUseCase>(),
      getUserTeamIds: sl<GetUserTeamIdsUseCase>(),
    );
    _teamsBloc.add(const LoadTeams());

    _inviteBloc = sl<InviteBloc>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersBloc.close();
    _teamsBloc.close();
    _inviteBloc.close();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;

    final repository = sl<OrganizationRepository>();
    try {
      await repository.updateOrganizationName(
        widget.organizationId,
        _nameController.text.trim(),
      );
      _membersBloc.add(LoadMembers(widget.organizationId));

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization name updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _membersBloc),
        BlocProvider.value(value: _teamsBloc),
        BlocProvider.value(value: _inviteBloc),
      ],
      child: BlocListener<InviteBloc, InviteState>(
        listener: (context, state) {
          if (state.status == InviteStatus.success) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) =>
                  InviteLinkDialog(inviteLink: state.inviteLink!),
            );
          } else if (state.status == InviteStatus.failure) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Error al generar invitación',
                ),
              ),
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

            final currentUserRole = state.members
                .where((m) => m.profileId == currentUserId)
                .firstOrNull
                ?.role;

            final canEditName = currentUserRole == OrganizationRole.owner;

            final canInvite = currentUserId.isNotEmpty &&
                (currentUserRole == OrganizationRole.owner ||
                    currentUserRole == OrganizationRole.admin);

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: _isEditing
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
                            value: _inviteBloc,
                            child: InviteModal(
                              organizationId: widget.organizationId,
                            ),
                          ),
                        ),
                      ),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _saveName,
                      )
                    else if (canEditName)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                  ],
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Members'),
                      Tab(text: 'Teams'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saveName,
                                    child: const Text('Save'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _nameController.text =
                                          state.organization!.name;
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
                          child: state.members.isEmpty
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
                                              targetProfileId:
                                                  member.profileId,
                                              organization:
                                                  state.organization!,
                                              currentUserId: currentUserId,
                                            );

                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          member.firstName.isNotEmpty
                                              ? member.firstName[0]
                                                  .toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      title: Text(
                                        '${member.firstName} ${member.lastName}'
                                            .trim(),
                                      ),
                                      subtitle: Text(member.email),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RolePicker(
                                            role: member.role,
                                            isInteractive: canChangeRole,
                                            onRoleSelected: (newRole) {
                                              _membersBloc.add(
                                                UpdateMemberRole(
                                                  organizationId:
                                                      widget.organizationId,
                                                  profileId: member.profileId,
                                                  newRole: newRole,
                                                ),
                                              );
                                            },
                                          ),
                                          if (isCurrentUser)
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 8),
                                              child: Text(
                                                '(You)',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
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
                    const TeamsTab(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
