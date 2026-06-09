import 'dart:async';

import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/failures/comment_failure.dart';
import 'package:hookra/src/preview/domain/repos/comment_repository.dart';
import 'package:hookra/src/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseCommentRepository extends CommentRepository {
  SupabaseCommentRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Stream<List<Comment>> watchComments(String contentId) {
    // ignore: close_sinks
    final controller = StreamController<List<Comment>>();
    RealtimeChannel? channel;

    Future<void> fetchAndEmit() async {
      if (controller.isClosed) return;
      try {
        final data = await _supabase
            .from('content_comments')
            .select('*, profiles!user_id(first_name, last_name)')
            .eq('content_id', contentId)
            .order('created_at', ascending: true);
        if (!controller.isClosed) {
          controller.add(
            data.map(Comment.fromJson).toList(),
          );
        }
      } catch (e, s) {
        if (!controller.isClosed) {
          controller.addError(const WatchCommentsFailed(), s);
        }
      }
    }

    controller.onListen = () async {
      channel = _supabase
          .channel('content_comments:$contentId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'content_comments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'content_id',
              value: contentId,
            ),
            callback: (_) => fetchAndEmit(),
          )
          .subscribe();
      await fetchAndEmit();
    };

    controller.onCancel = () async {
      try {
        if (channel != null) await _supabase.removeChannel(channel!);
      } finally {
        await controller.close();
      }
    };

    return controller.stream;
  }

  @override
  Future<Result<void>> addComment(String contentId, String body) async {
    try {
      await _supabase.from('content_comments').insert({
        'content_id': contentId,
        'user_id': _supabase.auth.currentUser!.id,
        'body': body,
      });
      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseCommentRepository.addComment',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<void>> editComment(String commentId, String body) async {
    try {
      await _supabase
          .from('content_comments')
          .update({
            'body': body,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', commentId);
      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseCommentRepository.editComment',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<void>> deleteComment(String commentId) async {
    try {
      await _supabase.from('content_comments').delete().eq('id', commentId);
      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseCommentRepository.deleteComment',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void dispose() {}
}
