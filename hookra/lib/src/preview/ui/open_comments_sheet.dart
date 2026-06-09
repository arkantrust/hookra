import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/auth/ui/blocs/auth_bloc/auth_bloc.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/preview/domain/use_cases/add_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/delete_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/edit_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/resolve_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/watch_comments_use_case.dart';
import 'package:hookra/src/preview/ui/widgets/comments_sheet.dart';

/// Opens [CommentsSheet] for [contentId] as a modal bottom sheet.
///
/// Reads the current user id from [AuthBloc] and resolves use-case instances
/// from the service locator, matching the wiring in [PreviewPage].
void openCommentsSheet(BuildContext context, String contentId) {
  final userId = context.read<AuthBloc>().state.user.id;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => CommentsSheet(
      contentId: contentId,
      currentUserId: userId,
      watchComments: sl<WatchCommentsUseCase>(),
      addComment: sl<AddCommentUseCase>(),
      editComment: sl<EditCommentUseCase>(),
      deleteComment: sl<DeleteCommentUseCase>(),
      resolveComment: sl<ResolveCommentUseCase>(),
    ),
  );
}
