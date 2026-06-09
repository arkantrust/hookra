import 'package:hookra/src/preview/domain/repos/comment_repository.dart';
import 'package:hookra/src/utils/result.dart';

class AddCommentUseCase {
  AddCommentUseCase(this._repository);

  final CommentRepository _repository;

  Future<Result<void>> call({
    required String contentId,
    required String body,
  }) =>
      _repository.addComment(contentId, body);
}
