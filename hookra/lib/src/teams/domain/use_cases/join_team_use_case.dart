import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class JoinTeamUseCase {
  const JoinTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<void>> call({
    required String teamId,
    required String profileId,
    required String organizationId,
  }) => _repository.joinTeam(
    teamId: teamId,
    profileId: profileId,
    organizationId: organizationId,
  );
}
