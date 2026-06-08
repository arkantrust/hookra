import 'package:flutter/material.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.team,
    required this.isInTeam,
    required this.onJoin,
    required this.onLeave,
    required this.onViewMembers,
    this.onDelete,
    this.isJoiningOrLeaving = false,
  });

  final Team team;
  final bool isInTeam;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onViewMembers;
  final VoidCallback? onDelete;
  final bool isJoiningOrLeaving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 8, right: 8),
      child: GestureDetector(
        onTap: onViewMembers,
        child: ListTile(
          leading: CircleAvatar(child: Text(team.name[0].toUpperCase())),
          title: Text(team.name),
          subtitle: Text(
            'Created ${team.createdAt.day}/${team.createdAt.month}/${team.createdAt.year}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isJoiningOrLeaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isInTeam)
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  tooltip: 'Leave team',
                  onPressed: onLeave,
                )
              else
                IconButton(
                  icon: const Icon(Icons.group_add),
                  tooltip: 'Join team',
                  onPressed: onJoin,
                ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete team',
                  color: Colors.red,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
