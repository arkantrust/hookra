import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/repos/comment_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetTeamCommentsUseCase {
  GetTeamCommentsUseCase(this._repository);

  final CommentRepository _repository;

  Future<Result<List<Comment>>> call(String teamId) =>
      _repository.getUnresolvedCommentsForTeam(teamId);
}
