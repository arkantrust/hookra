import 'package:hookra/src/preview/domain/repos/comment_repository.dart';
import 'package:hookra/src/utils/result.dart';

class DeleteCommentUseCase {
  DeleteCommentUseCase(this._repository);

  final CommentRepository _repository;

  Future<Result<void>> call(String commentId) =>
      _repository.deleteComment(commentId);
}
