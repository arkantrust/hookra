import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/ui/pages/organization_details_page.dart';
import 'package:hookra/src/organizations/data/repo/organization_repository_impl.dart';
import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/usecase/update_member_role_usecase.dart';
import 'package:hookra/src/organizations/ui/bloc/organization_members_bloc.dart';
import 'package:hookra/src/organizations/ui/organization_members_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  static GoRoute route() {
    return GoRoute(
      path: '/organizations',
      builder: (context, state) => const OrganizationsPage(),
    );
  }

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final OrganizationRepository _repository = sl<OrganizationRepository>();
  late Future<List<OrganizationWithRole>> _organizationsFuture;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  void _loadOrganizations() {
    _organizationsFuture = _repository.getOrganizationsForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<OrganizationWithRole>>(
        future: _organizationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadOrganizations();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final organizations = snapshot.data ?? [];

          if (organizations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No organizations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first organization to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadOrganizations();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: organizations.length,
              itemBuilder: (context, index) {
                final orgWithRole = organizations[index];
                return _OrganizationCard(
                  organization: orgWithRole.organization,
                  role: orgWithRole.role,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'members',
            onPressed: () => _openMembersPage(context),
            tooltip: 'Manage Members',
            child: const Icon(Icons.people),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => _showCreateOrganizationDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _openMembersPage(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userId = user.id;
    final dataSource = OrganizationDataSource();
    final repository = OrganizationRepositoryImpl(dataSource);

    final organization = await repository.getUserOrganization(userId);

    if (organization == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No perteneces a ninguna organización')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OrganizationMembersBloc(
            repository: repository,
            updateRoleUseCase: UpdateMemberRoleUseCase(repository),
            currentUserProfileId: userId,
          )..add(LoadOrganizationMembers(organization.id)),
          child: Scaffold(
            appBar: AppBar(title: Text(organization.name)),
            body: OrganizationMembersPage(
              organizationId: organization.id,
              currentUserProfileId: userId,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateOrganizationDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Organization'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            hintText: 'Enter organization name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                return;
              }
              
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  final organization = await _repository.createOrganization(
                    nameController.text.trim(),
                    user.id,
                  );
                  await _repository.addMember(organization.id, user.id, 'member');
                  
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    setState(() {
                      _loadOrganizations();
                    });
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  final dynamic organization;
  final dynamic role;

  const _OrganizationCard({
    required this.organization,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            organization.name.isNotEmpty ? organization.name[0].toUpperCase() : 'O',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          organization.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          role == OrganizationRole.owner ? 'Owner' : 'Member',
          style: TextStyle(
            color: role == OrganizationRole.owner ? Colors.green : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizationDetailsPage(
                organizationId: organization.id,
              ),
            ),
          );
        },
      ),
    );
  }
}