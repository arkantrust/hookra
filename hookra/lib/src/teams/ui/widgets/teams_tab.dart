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
          prev.status != curr.status && curr.status == TeamsStatus.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Failed to load teams'),
          ),
        );
      },
      builder: (context, state) {
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
                itemBuilder: (context, index) =>
                    TeamCard(team: state.teams[index]),
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
