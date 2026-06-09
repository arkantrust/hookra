import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/failures/comment_failure.dart';
import 'package:hookra/src/utils/result.dart';

abstract base class CommentRepository {
  /// Emits the current list of comments for [contentId] and updates in real time.
  ///
  /// Stream errors are delivered as [WatchCommentsFailed].
  Stream<List<Comment>> watchComments(String contentId);

  /// Inserts a new comment. The [userId] is read from the active Supabase session.
  Future<Result<void>> addComment(String contentId, String body);
  Future<Result<void>> editComment(String commentId, String body);
  Future<Result<void>> deleteComment(String commentId);
  void dispose();
}
