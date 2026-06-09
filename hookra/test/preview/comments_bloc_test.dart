import 'dart:async';

import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/failures/comment_failure.dart';
import 'package:hookra/src/preview/domain/repos/comment_repository.dart';
import 'package:hookra/src/preview/domain/use_cases/add_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/delete_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/edit_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/watch_comments_use_case.dart';
import 'package:hookra/src/preview/ui/blocs/comments_bloc/comments_bloc.dart';
import 'package:hookra/src/utils/result.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

base class _FakeCommentRepository extends CommentRepository {
  _FakeCommentRepository({
    required this.stream,
    Result<void> Function()? addResult,
    Result<void> Function()? editResult,
    Result<void> Function()? deleteResult,
  })  : _addResult = addResult ?? (() => Result.voidResult()),
        _editResult = editResult ?? (() => Result.voidResult()),
        _deleteResult = deleteResult ?? (() => Result.voidResult());

  final Stream<List<Comment>> stream;
  final Result<void> Function() _addResult;
  final Result<void> Function() _editResult;
  final Result<void> Function() _deleteResult;

  @override
  Stream<List<Comment>> watchComments(String contentId) => stream;

  @override
  Future<Result<void>> addComment(String contentId, String body) async =>
      _addResult();

  @override
  Future<Result<void>> editComment(String commentId, String body) async =>
      _editResult();

  @override
  Future<Result<void>> deleteComment(String commentId) async => _deleteResult();

  @override
  void dispose() {}
}

CommentsBloc _bloc(_FakeCommentRepository repo) => CommentsBloc(
      watchComments: WatchCommentsUseCase(repo),
      addComment: AddCommentUseCase(repo),
      editComment: EditCommentUseCase(repo),
      deleteComment: DeleteCommentUseCase(repo),
    );

final _sampleComment = Comment(
  id: 'c1',
  contentId: 'content-1',
  userId: 'u1',
  authorName: 'Alice',
  body: 'Nice!',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CommentsBloc', () {
    test('initial state is CommentsInitial', () {
      final streamCtrl = StreamController<List<Comment>>();
      final bloc = _bloc(_FakeCommentRepository(stream: streamCtrl.stream));
      expect(bloc.state, isA<CommentsInitial>());
      bloc.close();
      streamCtrl.close();
    });

    test('emits CommentsLoading then CommentsLoaded on watch requested',
        () async {
      final streamCtrl = StreamController<List<Comment>>();
      final bloc = _bloc(_FakeCommentRepository(stream: streamCtrl.stream));

      final states = <CommentsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const CommentsWatchRequested('content-1'));
      await Future<void>.delayed(Duration.zero);

      streamCtrl.add([_sampleComment]);
      await Future<void>.delayed(Duration.zero);

      expect(states, [isA<CommentsLoading>(), isA<CommentsLoaded>()]);
      expect((states.last as CommentsLoaded).comments, [_sampleComment]);

      await sub.cancel();
      await bloc.close();
      await streamCtrl.close();
    });

    test('CommentsLoaded.actionError is set when addComment fails', () async {
      final streamCtrl = StreamController<List<Comment>>();
      final bloc = _bloc(
        _FakeCommentRepository(
          stream: streamCtrl.stream,
          addResult: () => Result.failure(const AddCommentFailed()),
        ),
      );

      // Reach CommentsLoaded first.
      bloc.add(const CommentsWatchRequested('content-1'));
      await Future<void>.delayed(Duration.zero);
      streamCtrl.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<CommentsLoaded>());

      final states = <CommentsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const CommentAdded('Hello'));
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<CommentsLoaded>());
      expect((states.last as CommentsLoaded).actionError, isNotNull);

      await sub.cancel();
      await bloc.close();
      await streamCtrl.close();
    });

    test('CommentsActionErrorCleared clears actionError', () async {
      final streamCtrl = StreamController<List<Comment>>();
      final bloc = _bloc(
        _FakeCommentRepository(
          stream: streamCtrl.stream,
          addResult: () => Result.failure(const AddCommentFailed()),
        ),
      );

      bloc.add(const CommentsWatchRequested('content-1'));
      await Future<void>.delayed(Duration.zero);
      streamCtrl.add([]);
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CommentAdded('Hi'));
      await Future<void>.delayed(Duration.zero);

      final states = <CommentsState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(const CommentsActionErrorCleared());
      await Future<void>.delayed(Duration.zero);

      expect((states.last as CommentsLoaded).actionError, isNull);

      await sub.cancel();
      await bloc.close();
      await streamCtrl.close();
    });

    test('CommentsLoaded.actionError is set when editComment fails', () async {
      final streamCtrl = StreamController<List<Comment>>();
      final bloc = _bloc(
        _FakeCommentRepository(
          stream: streamCtrl.stream,
          editResult: () => Result.failure(const EditCommentFailed()),
        ),
      );

      bloc.add(const CommentsWatchRequested('content-1'));
      await Future<void>.delayed(Duration.zero);
      streamCtrl.add([_sampleComment]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<CommentsLoaded>());

      final states = <CommentsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const CommentEdited('c1', 'Updated'));
      await Future<void>.delayed(Duration.zero);

      expect((states.last as CommentsLoaded).actionError, isNotNull);

      await sub.cancel();
      await bloc.close();
      await streamCtrl.close();
    });

    test('CommentsLoaded.actionError is set when deleteComment fails', () async {
      final streamCtrl = StreamController<List<Comment>>();
      final bloc = _bloc(
        _FakeCommentRepository(
          stream: streamCtrl.stream,
          deleteResult: () => Result.failure(const DeleteCommentFailed()),
        ),
      );

      bloc.add(const CommentsWatchRequested('content-1'));
      await Future<void>.delayed(Duration.zero);
      streamCtrl.add([_sampleComment]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<CommentsLoaded>());

      final states = <CommentsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const CommentDeleted('c1'));
      await Future<void>.delayed(Duration.zero);

      expect((states.last as CommentsLoaded).actionError, isNotNull);

      await sub.cancel();
      await bloc.close();
      await streamCtrl.close();
    });
  });
}
