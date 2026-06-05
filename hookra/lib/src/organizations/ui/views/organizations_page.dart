import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/ui/blocs/organizations_bloc/organizations_bloc.dart';

class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({super.key});

  static GoRoute route() {
    return GoRoute(
      path: '/organizations',
      builder: (context, state) => const OrganizationsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrganizationsBloc>()..add(const OrganizationsLoadRequested()),
      child: const _OrganizationsView(),
    );
  }
}

class _OrganizationsView extends StatelessWidget {
  const _OrganizationsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizationsBloc, OrganizationsState>(
      listener: (context, state) {
        if (state.status == OrganizationsStatus.createFailure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Your Organizations', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ),
          body: _buildBody(context, state),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateOrganizationDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OrganizationsState state) {
    if (state.status == OrganizationsStatus.loading ||
        state.status == OrganizationsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == OrganizationsStatus.failure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'An error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<OrganizationsBloc>()
                    .add(const OrganizationsLoadRequested());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.organizations.isEmpty) {
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
        context
            .read<OrganizationsBloc>()
            .add(const OrganizationsLoadRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.organizations.length,
        itemBuilder: (context, index) {
          final orgWithRole = state.organizations[index];
          return _OrganizationCard(
            organization: orgWithRole.organization,
            role: orgWithRole.role,
          );
        },
      ),
    );
  }

  void _showCreateOrganizationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final currentUserId = context.read<AuthBloc>().state.user.id;

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
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty || currentUserId.isEmpty) return;

                  context.read<OrganizationsBloc>().add(
                    OrganizationsCreateRequested(
                      name: name,
                      ownerId: currentUserId,
                    ),
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  final Organization organization;
  final OrganizationRole role;

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
        onTap: () => context.push('/organizations/${organization.id}'),
      ),
    );
  }
}
