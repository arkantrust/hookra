import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/ui/pages/organization_details_page.dart';

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
                  const Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrganizationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateOrganizationDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
                      await _repository.addMember(
                        organization.id,
                        user.id,
                        'member',
                      );

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
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  const _OrganizationCard({required this.organization, required this.role});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            organization.name.isNotEmpty
                ? organization.name[0].toUpperCase()
                : 'O',
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
              builder:
                  (_) =>
                      OrganizationDetailsPage(organizationId: organization.id),
            ),
          );
        },
      ),
    );
  }
}
