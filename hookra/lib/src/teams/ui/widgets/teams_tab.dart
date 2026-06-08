import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/selection/selection.dart';
import 'package:hookra/src/teams/ui/blocs/teams_bloc/teams_bloc.dart';
import 'package:hookra/src/teams/ui/widgets/create_team_modal.dart';
import 'package:hookra/src/teams/ui/widgets/team_card.dart';
import 'package:hookra/src/teams/ui/widgets/team_members_modal.dart';

class TeamsTab extends StatelessWidget {
  const TeamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamsBloc, TeamsState>(
      listenWhen: (prev, curr) =>
          curr.status == TeamsStatus.error ||
          curr.status == TeamsStatus.createSuccess ||
          curr.status == TeamsStatus.deleteSuccess ||
          (curr.lastAction != TeamsAction.none &&
              prev.lastAction != curr.lastAction),
      listener: (context, state) {
        if (state.status == TeamsStatus.createSuccess ||
            state.status == TeamsStatus.deleteSuccess) {
          context.read<SelectionCubit>().refreshTeams();
        } else if (state.status == TeamsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        } else if (state.lastAction == TeamsAction.joined) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Unión exitosa!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state.lastAction == TeamsAction.left) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Saliste del equipo exitosamente!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state.status == TeamsStatus.loading ||
            state.status == TeamsStatus.joining ||
            state.status == TeamsStatus.leaving;
        final isOwner =
            context.read<SelectionCubit>().state.selectedOrg?.role ==
            OrganizationRole.owner;

        return Stack(
          children: [
            if (state.status == TeamsStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.teams.isEmpty)
              const Center(
                child: Text(
                  'No teams yet.\nCreate one for a client.',
                  textAlign: TextAlign.center,
                ),
              )
            else
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 6),
                 child: ListView.builder(
                   itemCount: state.teams.length,
                   itemBuilder: (context, index) {
                     final team = state.teams[index];
                     final isInThisTeam = state.isInTeam(team.id);
                     return TeamCard(
                       team: team,
                       isInTeam: isInThisTeam,
                       onJoin: () {
                         context.read<TeamsBloc>().add(JoinTeam(team.id));
                       },
                       onLeave: () {
                         context.read<TeamsBloc>().add(LeaveTeam(team.id));
                       },
                       onDelete: isOwner
                           ? () => _confirmDelete(context, team.id, team.name)
                           : null,
                       onViewMembers: () => showModalBottomSheet<void>(
                         context: context,
                         isScrollControlled: true,
                         builder: (_) => TeamMembersModal(team: team),
                       ),
                       isJoiningOrLeaving: isLoading,
                     );
                   },
                 ),
               ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'create_team_fab',
                onPressed: () {
                  final teamsBloc = context.read<TeamsBloc>();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BlocProvider.value(
                      value: teamsBloc,
                      child: const CreateTeamModal(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String teamId, String teamName) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar equipo?'),
        content: Text(
          '"$teamName" dejará de aparecer en la lista y no se contará en los stats. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TeamsBloc>().add(DeleteTeam(teamId));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
