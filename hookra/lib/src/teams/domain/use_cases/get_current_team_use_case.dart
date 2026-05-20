import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetCurrentTeamUseCase {
  const GetCurrentTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<Team?>> call({
    required String profileId,
    required String organizationId,
  }) =>
      _repository.getCurrentTeamForUser(profileId, organizationId);
}