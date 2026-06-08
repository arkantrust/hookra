import 'package:flutter/material.dart';

/// Display metadata for a content platform/format enum value.
class ContentBadge {
  const ContentBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

ContentBadge platformBadge(String platform) => switch (platform) {
  'instagram' => const ContentBadge(
    label: 'Instagram',
    icon: Icons.camera_alt_outlined,
    color: Color(0xFFE1306C),
  ),
  'tiktok' => const ContentBadge(
    label: 'TikTok',
    icon: Icons.music_note_outlined,
    color: Color(0xFF010101),
  ),
  'facebook' => const ContentBadge(
    label: 'Facebook',
    icon: Icons.facebook_outlined,
    color: Color(0xFF1877F2),
  ),
  'linkedin' => const ContentBadge(
    label: 'LinkedIn',
    icon: Icons.work_outline,
    color: Color(0xFF0A66C2),
  ),
  'twitter' => const ContentBadge(
    label: 'Twitter',
    icon: Icons.alternate_email,
    color: Color(0xFF1DA1F2),
  ),
  'youtube' => const ContentBadge(
    label: 'YouTube',
    icon: Icons.smart_display_outlined,
    color: Color(0xFFFF0000),
  ),
  _ => ContentBadge(
    label: platform,
    icon: Icons.public,
    color: Colors.grey.shade600,
  ),
};

ContentBadge formatBadge(String format) => switch (format) {
  'reel' => const ContentBadge(
    label: 'Reel',
    icon: Icons.movie_outlined,
    color: Color(0xFF7C3AED),
  ),
  'story' => const ContentBadge(
    label: 'Story',
    icon: Icons.auto_stories_outlined,
    color: Color(0xFFEA580C),
  ),
  'post' => const ContentBadge(
    label: 'Post',
    icon: Icons.article_outlined,
    color: Color(0xFF2563EB),
  ),
  'video' => const ContentBadge(
    label: 'Video',
    icon: Icons.videocam_outlined,
    color: Color(0xFFDC2626),
  ),
  'image' => const ContentBadge(
    label: 'Image',
    icon: Icons.image_outlined,
    color: Color(0xFF059669),
  ),
  'carousel' => const ContentBadge(
    label: 'Carousel',
    icon: Icons.view_carousel_outlined,
    color: Color(0xFF0891B2),
  ),
  'text' => const ContentBadge(
    label: 'Text',
    icon: Icons.notes_outlined,
    color: Color(0xFF6B7280),
  ),
  _ => ContentBadge(
    label: format,
    icon: Icons.description_outlined,
    color: Colors.grey.shade600,
  ),
};

String statusLabel(String status) => switch (status) {
  'draft' => 'Borrador',
  'in_review' => 'En revisión',
  'changes_requested' => 'Cambios solicitados',
  'approved' => 'Aprobado',
  'published' => 'Publicado',
  'archived' => 'Archivado',
  _ => status,
};
