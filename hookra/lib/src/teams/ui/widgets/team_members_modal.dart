import 'package:flutter/material.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/entities/team_member.dart';
import 'package:hookra/src/teams/domain/use_cases/get_team_members_use_case.dart';
import 'package:hookra/src/utils/result.dart';

class TeamMembersModal extends StatefulWidget {
  const TeamMembersModal({super.key, required this.team});

  final Team team;

  @override
  State<TeamMembersModal> createState() => _TeamMembersModalState();
}

class _TeamMembersModalState extends State<TeamMembersModal> {
  late final Future<Result<List<TeamMember>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = sl<GetTeamMembersUseCase>()(widget.team.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.team.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          FutureBuilder<Result<List<TeamMember>>>(
            future: _membersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final result = snapshot.data!;
              if (result.isFailure) {
                return Center(child: Text(result.error.toString()));
              }
              final members = result.value;
              if (members.isEmpty) {
                return const Center(child: Text('No members yet.'));
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 4.0,
                      left: 2,
                      right: 2,
                    ),
                    child: ListTile(
                      title: Text(members[index].fullName),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
