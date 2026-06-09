import 'package:flutter/material.dart';

import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/preview/ui/widgets/content_formatting.dart';

/// Renders a [Content] piece in a nicely formatted, sectioned card.
class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.content});

  final Content content;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final platform = platformBadge(content.platform);
    final format = formatBadge(content.format);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header: title + platform/format/status chips.
        Text(
          content.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(badge: platform),
            _Badge(badge: format),
            _StatusChip(status: content.status, palette: palette),
          ],
        ),
        const SizedBox(height: 24),

        if (content.hook != null && content.hook!.isNotEmpty)
          _Section(
            label: 'HOOK',
            icon: Icons.bolt_outlined,
            palette: palette,
            child: Text(
              content.hook!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),

        if (content.script != null && content.script!.isNotEmpty)
          _Section(
            label: 'SCRIPT',
            icon: Icons.description_outlined,
            palette: palette,
            child: Text(
              content.script!,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),

        if (content.caption != null && content.caption!.isNotEmpty)
          _Section(
            label: 'CAPTION',
            icon: Icons.chat_bubble_outline,
            palette: palette,
            child: Text(
              content.caption!,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),

        if (content.cta != null && content.cta!.isNotEmpty)
          _Section(
            label: 'CALL TO ACTION',
            icon: Icons.campaign_outlined,
            palette: palette,
            child: Text(
              content.cta!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.primary,
                height: 1.4,
              ),
            ),
          ),

        if (content.hashtags.isNotEmpty)
          _Section(
            label: 'HASHTAGS',
            icon: Icons.tag,
            palette: palette,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in content.hashtags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.palette,
    required this.child,
  });

  final String label;
  final IconData icon;
  final ColorScheme palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: palette.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.outlineVariant),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});

  final ContentBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 15, color: badge.color),
          const SizedBox(width: 6),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: badge.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.palette});

  final ContentStatus status;
  final ColorScheme palette;

  Color _getStatusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.draft:
        return Colors.orange;
      case ContentStatus.approved:
        return Colors.green;
      case ContentStatus.published:
        return Colors.blue;
    }
  }

  String _getStatusLabel(ContentStatus status) {
    return status.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
