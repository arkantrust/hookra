import 'package:flutter/material.dart';
import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/teams/teams.dart';

class StatTileData {
  const StatTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class ActivityData {
  const ActivityData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.contentId,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final String? contentId;
}

class HomeData {
  const HomeData({required this.stats, required this.activity});

  final List<StatTileData> stats;
  final List<ActivityData> activity;
}

/// Builds real stats from the org's loaded teams and activity from comments.
///
/// - Clientes   = total teams
/// - Campañas   = total teams
/// - Reels      = teams with state == 'published'
/// - Aprobados  = teams with state == 'approved'
HomeData homeDataFromTeams(List<Team> teams, List<Comment> comments) {
  final total = teams.length;
  final published = teams.where((t) => t.state == 'published').length;
  final approved = teams.where((t) => t.state == 'approved').length;

  return HomeData(
    stats: [
      StatTileData(
        label: 'Clients',
        value: '$total',
        icon: Icons.handshake_outlined,
        color: const Color(0xFF1E88E5),
      ),
      StatTileData(
        label: 'Projects',
        value: '$total',
        icon: Icons.campaign_outlined,
        color: const Color(0xFF6750A4),
      ),
      StatTileData(
        label: 'Reels',
        value: '$published',
        icon: Icons.movie_outlined,
        color: const Color(0xFF43A047),
      ),
      StatTileData(
        label: 'Approved',
        value: '$approved',
        icon: Icons.check_circle_outline,
        color: const Color(0xFFF4511E),
      ),
    ],
    activity: [
      for (final c in comments)
        ActivityData(
          title: c.body,
          subtitle: '${c.authorName} · ${c.contentTitle ?? 'Content'}',
          time: _relativeTime(c.createdAt),
          icon: Icons.comment_outlined,
          contentId: c.contentId,
        ),
    ],
  );
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return ' ${diff.inMinutes} min';
  if (diff.inHours < 24) return ' ${diff.inHours} h';
  if (diff.inDays == 1) return 'Yesterday';
  return ' ${diff.inDays} days';
}
