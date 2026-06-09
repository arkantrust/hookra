import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/use_cases/add_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/delete_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/edit_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/resolve_comment_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/watch_comments_use_case.dart';
import 'package:hookra/src/preview/ui/blocs/comments_bloc/comments_bloc.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.contentId,
    required this.currentUserId,
    required this.watchComments,
    required this.addComment,
    required this.editComment,
    required this.deleteComment,
    required this.resolveComment,
  });

  final String contentId;
  final String currentUserId;
  final WatchCommentsUseCase watchComments;
  final AddCommentUseCase addComment;
  final EditCommentUseCase editComment;
  final DeleteCommentUseCase deleteComment;
  final ResolveCommentUseCase resolveComment;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final TextEditingController _inputController;
  bool _showResolved = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsBloc>(
      create: (_) => CommentsBloc(
        watchComments: widget.watchComments,
        addComment: widget.addComment,
        editComment: widget.editComment,
        deleteComment: widget.deleteComment,
        resolveComment: widget.resolveComment,
      )..add(CommentsWatchRequested(widget.contentId)),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: BlocConsumer<CommentsBloc, CommentsState>(
            listener: (context, state) {
              if (state is CommentsLoaded && state.actionError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.actionError!)),
                );
                context
                    .read<CommentsBloc>()
                    .add(const CommentsActionErrorCleared());
              }
            },
            builder: (context, state) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                _SheetHeader(
                  onClose: () => Navigator.of(context).pop(),
                ),
                Flexible(child: _buildBody(context, state)),
                _CommentInput(
                  controller: _inputController,
                  onSubmit: (body) {
                    context.read<CommentsBloc>().add(CommentAdded(body));
                    _inputController.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CommentsState state) {
    return switch (state) {
      CommentsInitial() || CommentsLoading() => const _CenteredPadding(
          child: CircularProgressIndicator(),
        ),
      CommentsError() => _CenteredPadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load comments.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context
                    .read<CommentsBloc>()
                    .add(CommentsWatchRequested(widget.contentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      CommentsLoaded(:final comments) => _buildLoaded(context, comments),
    };
  }

  Widget _buildLoaded(BuildContext context, List<Comment> comments) {
    final unresolved = comments.where((c) => !c.resolved).toList();
    final resolved = comments.where((c) => c.resolved).toList();

    if (unresolved.isEmpty && resolved.isEmpty) {
      return const _CenteredPadding(
        child: Text('No comments yet. Be the first!'),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        for (final c in unresolved)
          _CommentTile(
            comment: c,
            isOwner: c.userId == widget.currentUserId,
            isResolved: false,
            onEdit: (body) =>
                context.read<CommentsBloc>().add(CommentEdited(c.id, body)),
            onDelete: () =>
                context.read<CommentsBloc>().add(CommentDeleted(c.id)),
            onResolve: () =>
                context.read<CommentsBloc>().add(CommentResolved(c.id)),
          ),
        if (resolved.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () => setState(() => _showResolved = !_showResolved),
              child: Text(
                _showResolved
                    ? 'Hide resolved'
                    : 'Show resolved (${resolved.length})',
              ),
            ),
          ),
        if (_showResolved)
          for (final c in resolved)
            _CommentTile(
              comment: c,
              isOwner: c.userId == widget.currentUserId,
              isResolved: true,
              onEdit: (body) =>
                  context.read<CommentsBloc>().add(CommentEdited(c.id, body)),
              onDelete: () =>
                  context.read<CommentsBloc>().add(CommentDeleted(c.id)),
              onResolve: null,
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
      child: Row(
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}

class _CenteredPadding extends StatelessWidget {
  const _CenteredPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: child,
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwner,
    required this.isResolved,
    required this.onEdit,
    required this.onDelete,
    required this.onResolve,
  });

  final Comment comment;
  final bool isOwner;
  final bool isResolved;
  final void Function(String body) onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onResolve;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _editing = false;
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.body);
  }

  @override
  void didUpdateWidget(_CommentTile old) {
    super.didUpdateWidget(old);
    if (!_editing && old.comment.body != widget.comment.body) {
      _editController.text = widget.comment.body;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final textColor =
        widget.isResolved ? palette.onSurfaceVariant : palette.onSurface;

    if (_editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _editController,
                autofocus: true,
                maxLines: null,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check),
              color: palette.primary,
              tooltip: 'Save',
              onPressed: () {
                final body = _editController.text.trim();
                if (body.isNotEmpty) {
                  widget.onEdit(body);
                  setState(() => _editing = false);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () {
                _editController.text = widget.comment.body;
                setState(() => _editing = false);
              },
            ),
          ],
        ),
      );
    }

    return ListTile(
      title: Row(
        children: [
          Text(
            widget.comment.authorName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            _relativeTime(widget.comment.createdAt),
            style: TextStyle(fontSize: 11, color: palette.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          widget.comment.body,
          style: TextStyle(color: textColor),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onResolve != null)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              tooltip: 'Resolve',
              onPressed: widget.onResolve,
            ),
          if (widget.isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') setState(() => _editing = true);
                if (value == 'delete') widget.onDelete();
              },
            ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final void Function(String body) onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment…',
                border: InputBorder.none,
                isDense: true,
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: palette.primary),
            tooltip: 'Send',
            onPressed: () {
              final body = controller.text.trim();
              if (body.isNotEmpty) onSubmit(body);
            },
          ),
        ],
      ),
    );
  }
}
