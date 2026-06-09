import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/home/ui/cubit/home_activity_cubit.dart';
import 'package:hookra/src/home/ui/home_mock_data.dart';
import 'package:hookra/src/home/ui/widgets/activity_tile.dart';
import 'package:hookra/src/home/ui/widgets/stat_card.dart';
import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/ui/open_comments_sheet.dart';
import 'package:hookra/src/selection/selection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static GoRoute route() {
    return GoRoute(path: '/', builder: (context, state) => const HomePage());
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
          'Hookra',
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
            prev.selectedTeamId != curr.selectedTeamId ||
            prev.teams != curr.teams,
        builder: (context, state) {
          final teamId = state.selectedTeamId;

          if (teamId == null) {
            return _HomeBody(
              data: homeDataFromTeams(state.teams, const []),
              onActivityTap: null,
            );
          }

          return BlocProvider<HomeActivityCubit>(
            key: ValueKey(teamId),
            create: (_) => sl<HomeActivityCubit>()..load(teamId),
            child: BlocBuilder<HomeActivityCubit, HomeActivityState>(
              builder: (context, activityState) {
                final comments = activityState is HomeActivityReady
                    ? activityState.comments
                    : const <Comment>[];
                return _HomeBody(
                  data: homeDataFromTeams(state.teams, comments),
                  onActivityTap: (contentId) =>
                      openCommentsSheet(context, contentId),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data, required this.onActivityTap});

  final HomeData data;
  final void Function(String contentId)? onActivityTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Overview', palette: palette),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [for (final s in data.stats) StatCard(data: s)],
          ),
          const SizedBox(height: 24),
          _SectionTitle('Recent Activity', palette: palette),
          const SizedBox(height: 12),
          if (data.activity.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nothing to see here yet',
                  style: TextStyle(color: palette.onSurfaceVariant),
                ),
              ),
            )
          else
            for (final a in data.activity)
              ActivityTile(
                data: a,
                onTap: a.contentId != null && onActivityTap != null
                    ? () => onActivityTap!(a.contentId!)
                    : null,
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.palette});

  final String text;
  final ColorScheme palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: palette.onSurface,
      ),
    );
  }
}
