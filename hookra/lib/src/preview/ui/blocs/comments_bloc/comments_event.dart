part of 'comments_bloc.dart';

sealed class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object?> get props => [];
}

final class CommentsWatchRequested extends CommentsEvent {
  const CommentsWatchRequested(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

final class CommentAdded extends CommentsEvent {
  const CommentAdded(this.body);

  final String body;

  @override
  List<Object?> get props => [body];
}

final class CommentEdited extends CommentsEvent {
  const CommentEdited(this.commentId, this.body);

  final String commentId;
  final String body;

  @override
  List<Object?> get props => [commentId, body];
}

final class CommentDeleted extends CommentsEvent {
  const CommentDeleted(this.commentId);

  final String commentId;

  @override
  List<Object?> get props => [commentId];
}

final class CommentsActionErrorCleared extends CommentsEvent {
  const CommentsActionErrorCleared();
}
