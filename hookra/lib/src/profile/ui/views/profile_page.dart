import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/profile/ui/widgets/selection_field.dart';
import 'package:hookra/src/profile/ui/widgets/selection_picker.dart';
import 'package:hookra/src/selection/selection.dart';
import 'package:hookra/src/settings/settings.dart';
import 'package:hookra/src/teams/teams.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static GoRoute route() => GoRoute(path: '/profile', builder: (_, _) => const ProfilePage());

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final palette = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: palette.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 20,
        title: Text(
          'PERFIL',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: palette.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(user: user, palette: palette),
            const SizedBox(height: 12),
            _EmailCard(email: user.email, palette: palette),
            const SizedBox(height: 12),
            _SelectorCard(palette: palette),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'signout',
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.read<AuthBloc>().add(AuthSignOutPressed());
        },
        tooltip: 'Cerrar sesión',
        child: const Icon(Icons.logout),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;
  final ColorScheme palette;

  const _ProfileCard({required this.user, required this.palette});

  Widget _avatarPlaceholder(ColorScheme palette) =>
      Icon(Icons.person, size: 56, color: palette.onSurfaceVariant);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: palette.surfaceContainerHighest,
                  child: user.avatarUrl != null
                      ? Image.network(
                          user.avatarUrl!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _avatarPlaceholder(palette),
                          errorBuilder: (_, _, _) => _avatarPlaceholder(palette),
                        )
                      : _avatarPlaceholder(palette),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 2),
                    ),
                    child: Icon(Icons.camera_alt_outlined, size: 14, color: palette.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${user.firstName} ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: user.lastName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(EditProfilePage.route().path),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar Perfil'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  final String email;
  final ColorScheme palette;

  const _EmailCard({required this.email, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.email_outlined, size: 20, color: palette.onPrimaryContainer),
        ),
        title: Text(
          'CORREO ELECTRÓNICO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: palette.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          email,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: palette.onSurface),
        ),
      ),
    );
  }
}

class _SelectorCard extends StatefulWidget {
  final ColorScheme palette;

  const _SelectorCard({required this.palette});

  @override
  State<_SelectorCard> createState() => _SelectorCardState();
}

class _SelectorCardState extends State<_SelectorCard> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    context.read<SelectionCubit>().load(
      initialOrgId: user.selectedOrgId,
      initialTeamId: user.selectedTeamId,
    );
  }

  Future<void> _pickOrg(SelectionState state) async {
    final cubit = context.read<SelectionCubit>();
    final id = await showSelectionPicker<OrganizationWithRole>(
      context: context,
      title: 'Seleccionar organización',
      items: state.orgs,
      selectedId: state.selectedOrgId,
      idOf: (o) => o.organization.id,
      labelOf: (o) => o.organization.name,
    );
    if (id != null) cubit.selectOrg(id);
  }

  Future<void> _pickTeam(SelectionState state) async {
    final cubit = context.read<SelectionCubit>();
    final id = await showSelectionPicker<Team>(
      context: context,
      title: 'Seleccionar equipo',
      items: state.teams,
      selectedId: state.selectedTeamId,
      idOf: (t) => t.id,
      labelOf: (t) => t.name,
    );
    if (id != null) cubit.selectTeam(id);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, state) {
        final teamEnabled = state.selectedOrgId != null &&
            !state.teamsLoading &&
            state.teams.isNotEmpty;

        return Card(
          elevation: 0,
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTEXTO ACTIVO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: palette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SelectionField(
                  label: 'ORGANIZACIÓN',
                  value: state.selectedOrg?.organization.name,
                  icon: Icons.business_outlined,
                  onTap:
                      state.orgs.isEmpty ? null : () => _pickOrg(state),
                ),
                const SizedBox(height: 12),
                SelectionField(
                  label: 'EQUIPO',
                  value: state.teamsLoading
                      ? 'Cargando…'
                      : state.selectedTeam?.name,
                  icon: Icons.groups_outlined,
                  onTap: teamEnabled ? () => _pickTeam(state) : null,
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        context.push(OrganizationsPage.route().path),
                    child: const Text('Manage organizations'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}