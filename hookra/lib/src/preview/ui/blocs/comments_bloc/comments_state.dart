part of 'comments_bloc.dart';

sealed class CommentsState extends Equatable {
  const CommentsState();

  @override
  List<Object?> get props => [];
}

final class CommentsInitial extends CommentsState {
  const CommentsInitial();
}

final class CommentsLoading extends CommentsState {
  const CommentsLoading();
}

final class CommentsLoaded extends CommentsState {
  const CommentsLoaded(this.comments, {this.actionError});

  final List<Comment> comments;
  final String? actionError;

  CommentsLoaded copyWithError(String? error) =>
      CommentsLoaded(comments, actionError: error);

  @override
  List<Object?> get props => [comments, actionError];
}

final class CommentsError extends CommentsState {
  const CommentsError();
}
