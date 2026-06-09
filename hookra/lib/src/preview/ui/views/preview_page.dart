import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/preview/preview.dart';
import 'package:hookra/src/selection/selection.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  static GoRoute route() {
    return GoRoute(
      path: '/preview',
      builder: (context, state) => const PreviewPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: palette.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 20,
        title: Text(
          'PREVIEW',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: palette.primary,
          ),
        ),
      ),
      body: BlocBuilder<SelectionCubit, SelectionState>(
        buildWhen: (prev, curr) =>
            prev.selectedOrgId != curr.selectedOrgId ||
            prev.selectedTeamId != curr.selectedTeamId,
        builder: (context, selection) {
          final orgId = selection.selectedOrgId;
          final teamId = selection.selectedTeamId;

          if (orgId == null || teamId == null) {
            return const _NoSelection();
          }

          // Keyed by teamId so switching teams recreates the bloc and reloads.
          return BlocProvider<PreviewBloc>(
            key: ValueKey(teamId),
            create: (_) => sl<PreviewBloc>()..add(PreviewRequested(teamId)),
            child: _PreviewBody(teamId: teamId),
          );
        },
      ),
    );
  }
}

/// Same empty state as the chat: prompts the user to pick an org and team.
class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Select an organization and team to start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PreviewBloc, PreviewState>(
      listener: (context, state) {
        if (state is ContentApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contenido aprobado exitosamente')),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          PreviewInitial() ||
          PreviewLoading() ||
          ContentApproved() => const Center(child: CircularProgressIndicator()),
          PreviewError() => _Message(
              icon: Icons.error_outline,
              text: 'No se pudo cargar el contenido.',
              actionLabel: 'Reintentar',
              onAction: () =>
                  context.read<PreviewBloc>().add(PreviewRequested(teamId)),
            ),
          PreviewLoaded(:final content) =>
            content == null
                ? const _Message(
                    icon: Icons.inbox_outlined,
                    text: 'Aún no hay nada generado',
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async =>
                            context.read<PreviewBloc>().add(
                              PreviewRequested(teamId),
                            ),
                        child: ContentCard(content: content),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: () =>
                              openCommentsSheet(context, content.id),
                          child: const Icon(Icons.comment_outlined),
                        ),
                      ),
                      if (content.status == ContentStatus.draft)
                        Positioned(
                          bottom: 80,
                          right: 16,
                          child: FloatingActionButton(
                            heroTag: 'approve_content_fab',
                            onPressed: () => context
                                .read<PreviewBloc>()
                                .add(ApproveContent(content.id)),
                            child: const Icon(Icons.check),
                          ),
                        ),
                    ],
                  ),
        };
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
