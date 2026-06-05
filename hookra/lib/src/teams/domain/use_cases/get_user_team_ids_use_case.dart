import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetUserTeamIdsUseCase {
  const GetUserTeamIdsUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<List<String>>> call({
    required String profileId,
    required String organizationId,
  }) => _repository.getTeamIdsForUser(
    profileId: profileId,
    organizationId: organizationId,
  );
}
