import 'package:hookra/src/preview/domain/repos/comment_repository.dart';
import 'package:hookra/src/utils/result.dart';

class EditCommentUseCase {
  EditCommentUseCase(this._repository);

  final CommentRepository _repository;

  Future<Result<void>> call({
    required String commentId,
    required String body,
  }) =>
      _repository.editComment(commentId, body);
}
