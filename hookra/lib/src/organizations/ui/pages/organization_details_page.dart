import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/domain/auth/role_auth.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/ui/blocs/organization_members_bloc/organization_members_bloc.dart';
import 'package:hookra/src/organizations/ui/components/role_picker.dart';

class OrganizationDetailsPage extends StatefulWidget {
  final String organizationId;

  const OrganizationDetailsPage({super.key, required this.organizationId});

  @override
  State<OrganizationDetailsPage> createState() =>
      _OrganizationDetailsPageState();
}

class _OrganizationDetailsPageState extends State<OrganizationDetailsPage> {
  late final OrganizationMembersBloc _bloc;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  final _roleAuth = const RoleAuthorization();

  @override
  void initState() {
    super.initState();
    _bloc = OrganizationMembersBloc(
      repository: sl<OrganizationRepository>(),
      updateMemberRoleUseCase: sl(),
    );
    _bloc.add(LoadMembers(widget.organizationId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloc.close();
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
      _bloc.add(LoadMembers(widget.organizationId));

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization name updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocProvider.value(
      value: _bloc,
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
          if (state.status == OrganizationMembersStatus.loading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Organization')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state.status == OrganizationMembersStatus.initial) {
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
              currentUserId != null;

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
                            onPressed: _saveName,
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
                                  currentUserId != null &&
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
                                        _bloc.add(
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
}
