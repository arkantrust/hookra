import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/teams/ui/blocs/teams_bloc/teams_bloc.dart';
import 'package:hookra/src/teams/ui/widgets/create_team_modal.dart';
import 'package:hookra/src/teams/ui/widgets/team_card.dart';

class TeamsTab extends StatelessWidget {
  const TeamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamsBloc, TeamsState>(
      listenWhen: (prev, curr) =>
          curr.status == TeamsStatus.error ||
          (curr.lastAction != TeamsAction.none &&
              prev.lastAction != curr.lastAction),
      listener: (context, state) {
        if (state.status == TeamsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
            ),
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
               ListView.builder(
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
                     isJoiningOrLeaving: isLoading,
                   );
                 },
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
}
