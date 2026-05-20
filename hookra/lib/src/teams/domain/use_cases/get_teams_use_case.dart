import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetTeamsUseCase {
  const GetTeamsUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<List<Team>>> call(String organizationId) =>
      _repository.getTeamsForOrganization(organizationId);
}
