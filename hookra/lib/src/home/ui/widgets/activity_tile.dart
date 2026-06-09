import 'package:flutter/material.dart';
import 'package:hookra/src/home/ui/home_mock_data.dart';

/// A single recent-activity row in the home dashboard.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.data, this.onTap});

  final ActivityData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: palette.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(data.icon, size: 20, color: palette.onPrimaryContainer),
        ),
        title: Text(
          data.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.onSurface,
          ),
        ),
        subtitle: Text(
          data.subtitle,
          style: TextStyle(fontSize: 12, color: palette.onSurfaceVariant),
        ),
        trailing: Text(
          data.time,
          style: TextStyle(fontSize: 11, color: palette.onSurfaceVariant),
        ),
      ),
    );
  }
}
