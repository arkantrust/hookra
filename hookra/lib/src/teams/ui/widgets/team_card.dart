import 'package:flutter/material.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({super.key, required this.team});

  final Team team;

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
    );
  }
}
