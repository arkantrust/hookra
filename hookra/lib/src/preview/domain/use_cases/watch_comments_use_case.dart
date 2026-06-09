import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/repos/comment_repository.dart';

class WatchCommentsUseCase {
  WatchCommentsUseCase(this._repository);

  final CommentRepository _repository;

  Stream<List<Comment>> call(String contentId) =>
      _repository.watchComments(contentId);
}
