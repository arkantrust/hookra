import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/entities/team_member.dart';
import 'package:hookra/src/utils/result.dart';

abstract base class TeamRepository {
  Future<Result<List<Team>>> getTeamsForOrganization(String organizationId);

  Future<Result<Team>> createTeam({
    required String organizationId,
    required String name,
    required String creatorProfileId,
  });

  Future<Result<List<String>>> getTeamIdsForUser({
    required String profileId,
    required String organizationId,
  });

  Future<Result<void>> joinTeam({
    required String teamId,
    required String profileId,
    required String organizationId,
  });

  Future<Result<void>> leaveTeam({
    required String teamId,
    required String profileId,
  });

  Future<Result<List<TeamMember>>> getTeamMembers(String teamId);

  void dispose();
}
