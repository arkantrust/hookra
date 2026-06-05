import 'package:flutter/material.dart';

/// Mock/demo data backing the home dashboard.
///
/// These are hardcoded placeholders so the home screen looks alive during
/// demos. Replace with real data sources when the dashboard is wired up.

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

const mockStats = <StatTileData>[
  StatTileData(
    label: 'Campañas',
    value: '12',
    icon: Icons.campaign_outlined,
    color: Color(0xFF6750A4),
  ),
  StatTileData(
    label: 'Clientes',
    value: '8',
    icon: Icons.handshake_outlined,
    color: Color(0xFF1E88E5),
  ),
  StatTileData(
    label: 'Reels',
    value: '34',
    icon: Icons.movie_outlined,
    color: Color(0xFF43A047),
  ),
  StatTileData(
    label: 'Aprobados',
    value: '57',
    icon: Icons.check_circle_outline,
    color: Color(0xFFF4511E),
  ),
];

const mockActivity = <ActivityData>[
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
