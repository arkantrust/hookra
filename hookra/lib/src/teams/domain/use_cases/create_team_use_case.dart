import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class CreateTeamUseCase {
  const CreateTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<Team>> call({
    required String organizationId,
    required String name,
    required String creatorProfileId,
  }) => _repository.createTeam(
    organizationId: organizationId,
    name: name,
    creatorProfileId: creatorProfileId,
  );
}
