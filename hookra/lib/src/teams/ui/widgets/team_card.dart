import 'package:flutter/material.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.team,
    required this.isInTeam,
    required this.onJoin,
    required this.onLeave,
    this.isJoiningOrLeaving = false,
  });

  final Team team;
  final bool isInTeam;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final bool isJoiningOrLeaving;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(team.name[0].toUpperCase()),
      ),
      title: Text(team.name),
      subtitle: Text(
        'Created ${team.createdAt.day}/${team.createdAt.month}/${team.createdAt.year}',
      ),
      trailing: isJoiningOrLeaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isInTeam
              ? IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  tooltip: 'Leave team',
                  onPressed: onLeave,
                )
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Join team',
                  onPressed: onJoin,
                ),
    );
  }
}
