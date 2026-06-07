import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class DeleteTeamUseCase {
  const DeleteTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<void>> call(String teamId) => _repository.deleteTeam(teamId);
}
