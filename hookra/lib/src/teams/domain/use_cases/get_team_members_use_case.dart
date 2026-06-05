import 'package:hookra/src/teams/domain/entities/team_member.dart';
import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetTeamMembersUseCase {
  const GetTeamMembersUseCase(this._repository);

  final TeamRepository _repository;

  Future<Result<List<TeamMember>>> call(String teamId) =>
      _repository.getTeamMembers(teamId);
}
