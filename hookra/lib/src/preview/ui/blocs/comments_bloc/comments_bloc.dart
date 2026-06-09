import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/use_cases/add_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/delete_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/edit_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/watch_comments_use_case.dart';

part 'comments_event.dart';
part 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsBloc({
    required WatchCommentsUseCase watchComments,
    required AddCommentUseCase addComment,
    required EditCommentUseCase editComment,
    required DeleteCommentUseCase deleteComment,
  })  : _watchComments = watchComments,
        _addComment = addComment,
        _editComment = editComment,
        _deleteComment = deleteComment,
        super(const CommentsInitial()) {
    on<CommentsWatchRequested>(_onWatchRequested, transformer: restartable());
    on<CommentAdded>(_onAdded);
    on<CommentEdited>(_onEdited);
    on<CommentDeleted>(_onDeleted);
    on<CommentsActionErrorCleared>(_onActionErrorCleared);
  }

  final WatchCommentsUseCase _watchComments;
  final AddCommentUseCase _addComment;
  final EditCommentUseCase _editComment;
  final DeleteCommentUseCase _deleteComment;

  String? _contentId;

  Future<void> _onWatchRequested(
    CommentsWatchRequested event,
    Emitter<CommentsState> emit,
  ) async {
    _contentId = event.contentId;
    emit(const CommentsLoading());
    await emit.onEach(
      _watchComments(event.contentId),
      onData: (comments) => emit(CommentsLoaded(comments)),
      onError: (_, _) => emit(const CommentsError()),
    );
  }

  Future<void> _onAdded(
    CommentAdded event,
    Emitter<CommentsState> emit,
  ) async {
    final id = _contentId;
    if (id == null) return;
    final result = await _addComment(contentId: id, body: event.body);
    if (result.isFailure && state is CommentsLoaded) {
      emit((state as CommentsLoaded).copyWithError('Could not post comment.'));
    }
  }

  Future<void> _onEdited(
    CommentEdited event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _editComment(
      commentId: event.commentId,
      body: event.body,
    );
    if (result.isFailure && state is CommentsLoaded) {
      emit((state as CommentsLoaded).copyWithError('Could not update comment.'));
    }
  }

  Future<void> _onDeleted(
    CommentDeleted event,
    Emitter<CommentsState> emit,
  ) async {
    final result = await _deleteComment(event.commentId);
    if (result.isFailure && state is CommentsLoaded) {
      emit((state as CommentsLoaded).copyWithError('Could not delete comment.'));
    }
  }

  void _onActionErrorCleared(
    CommentsActionErrorCleared event,
    Emitter<CommentsState> emit,
  ) {
    if (state is CommentsLoaded) {
      emit((state as CommentsLoaded).copyWithError(null));
    }
  }
}
