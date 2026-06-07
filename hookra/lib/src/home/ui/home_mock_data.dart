import 'package:flutter/material.dart';
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
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
}

class HomeData {
  const HomeData({required this.stats, required this.activity});

  final List<StatTileData> stats;
  final List<ActivityData> activity;
}

const _mockActivity = [
  ActivityData(
    title: 'Client approved Summer 25% video',
    subtitle: 'Summer Sale · Bella Boutique',
    time: 'hace 12 min',
    icon: Icons.check_circle_outline,
  ),
  ActivityData(
    title: "Agent brainstormed for Caleñas VIP's grand opening",
    subtitle: 'Caleñas VIP · Launch',
    time: 'hace 1 h',
    icon: Icons.auto_awesome_outlined,
  ),
  ActivityData(
    title: 'New reel scheduled for review',
    subtitle: 'Instagram · Fitfuel',
    time: 'hace 3 h',
    icon: Icons.movie_outlined,
  ),
  ActivityData(
    title: 'Campaign brief generated',
    subtitle: 'Black Friday 2025 · Acme',
    time: 'ayer',
    icon: Icons.description_outlined,
  ),
  ActivityData(
    title: 'Ad creative exported to Meta Ads',
    subtitle: 'Caleñas VIP · Grand Opening',
    time: 'hace 2 días',
    icon: Icons.image_outlined,
  ),
];

/// Builds real stats from the org's loaded teams.
///
/// - Clientes   = total teams
/// - Campañas   = total teams
/// - Reels      = teams with state == 'published'
/// - Aprobados  = teams with state == 'approved'
HomeData homeDataFromTeams(List<Team> teams) {
  final total = teams.length;
  final published = teams.where((t) => t.state == 'published').length;
  final approved = teams.where((t) => t.state == 'approved').length;

  return HomeData(
    stats: [
      StatTileData(
        label: 'Clientes',
        value: '$total',
        icon: Icons.handshake_outlined,
        color: const Color(0xFF1E88E5),
      ),
      StatTileData(
        label: 'Campañas',
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
        label: 'Aprobados',
        value: '$approved',
        icon: Icons.check_circle_outline,
        color: const Color(0xFFF4511E),
      ),
    ],
    activity: _mockActivity,
  );
}
