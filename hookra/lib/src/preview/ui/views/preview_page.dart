import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
        builder: (context, state) {
          if (state.selectedOrgId == null || state.selectedTeamId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
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
          return const Center(child: Text('Preview'));
        },
      ),
    );
  }
}
