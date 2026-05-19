import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/utils/result.dart';

abstract base class TeamRepository {
  Future<Result<List<Team>>> getTeamsForOrganization(String organizationId);

  Future<Result<Team>> createTeam({
    required String organizationId,
    required String name,
    required String creatorProfileId,
  });

  void dispose();
}
