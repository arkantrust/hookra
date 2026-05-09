import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/data/repo/organization_repository_impl.dart';
import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/usecase/update_member_role_usecase.dart';
import 'package:hookra/src/organizations/ui/bloc/organization_members_bloc.dart';
import 'package:hookra/src/organizations/ui/organization_members_page.dart';

void _log(String msg) {
  print('DEBUG HomeScreen: $msg');
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 8),
              Text(user!.email!, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMembersPage(context),
        child: const Icon(Icons.people),
      ),
    );
  }

  void _openMembersPage(BuildContext context) async {
    _log('_openMembersPage started');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _log('User is null');
      return;
    }

    final userId = user.id;
    _log('UserId: $userId');
    
    final dataSource = OrganizationDataSource();
    final repository = OrganizationRepositoryImpl(dataSource);

    _log('Fetching organizations...');
    final organizations = await repository.getUserOrganizations(userId);
    _log('Organizations found: ${organizations.length}');

    if (organizations.isEmpty) {
      _log('No organizations');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No perteneces a ninguna organización')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (organizations.length == 1) {
      _log('Single org, navigating...');
      _navigateToMembers(context, organizations.first, repository, userId);
    } else {
      _log('Multiple orgs, showing picker...');
      _showOrganizationPicker(context, organizations, repository, userId);
    }
  }

  void _showOrganizationPicker(
    BuildContext context,
    List organizations,
    OrganizationRepositoryImpl repository,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Organización'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: organizations.length,
            itemBuilder: (context, index) {
              final org = organizations[index];
              return ListTile(
                title: Text(org.name),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToMembers(context, org, repository, userId);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToMembers(
    BuildContext context,
    organization,
    OrganizationRepositoryImpl repository,
    String userId,
  ) {
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
}
