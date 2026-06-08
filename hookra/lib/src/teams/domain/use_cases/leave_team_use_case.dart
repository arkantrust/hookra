import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class LeaveTeamUseCase {
  const LeaveTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<void>> call({
    required String teamId,
    required String profileId,
  }) => _repository.leaveTeam(teamId: teamId, profileId: profileId);
}
