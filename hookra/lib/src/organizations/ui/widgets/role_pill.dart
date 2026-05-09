import 'package:flutter/material.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';

class RolePill extends StatelessWidget {
  final OrgRole role;
  final bool canChange;
  final bool isUpdating;
  final ValueChanged<OrgRole> onRoleChanged;

  const RolePill({
    super.key,
    required this.role,
    required this.canChange,
    required this.isUpdating,
    required this.onRoleChanged,
  });

  String _roleLabel(OrgRole role) {
    return switch (role) {
      OrgRole.member => 'Miembro',
      OrgRole.admin => 'Administrador',
      OrgRole.owner => 'Propietario',
    };
  }

  Color _roleColor(OrgRole role, ColorScheme colorScheme) {
    return switch (role) {
      OrgRole.member => colorScheme.secondary,
      OrgRole.admin => colorScheme.primary,
      OrgRole.owner => colorScheme.tertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = _roleColor(role, colorScheme);

    if (!canChange || isUpdating) {
      return Chip(
        label: Text(
          _roleLabel(role),
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return PopupMenuButton<OrgRole>(
      initialValue: role,
      onSelected: onRoleChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => OrgRole.values.map((r) {
        return PopupMenuItem<OrgRole>(
          value: r,
          child: Row(
            children: [
              if (r == role)
                Icon(
                  Icons.check,
                  size: 18,
                  color: colorScheme.primary,
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(_roleLabel(r)),
            ],
          ),
        );
      }).toList(),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _roleLabel(role),
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: colorScheme.onSecondaryContainer,
            ),
          ],
        ),
        backgroundColor: roleColor.withValues(alpha: 0.15),
        side: BorderSide(color: roleColor),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}