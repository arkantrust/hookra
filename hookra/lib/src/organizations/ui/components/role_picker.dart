import 'package:flutter/material.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';

class RolePicker extends StatelessWidget {
  final OrganizationRole role;
  final bool isInteractive;
  final void Function(OrganizationRole) onRoleSelected;

  const RolePicker({
    super.key,
    required this.role,
    required this.isInteractive,
    required this.onRoleSelected,
  });

  Color _getRoleColor(OrganizationRole role) {
    switch (role) {
      case OrganizationRole.owner:
        return Colors.green;
      case OrganizationRole.admin:
        return Colors.blue;
      case OrganizationRole.member:
        return Colors.grey;
    }
  }

  String _getRoleLabel(OrganizationRole role) {
    switch (role) {
      case OrganizationRole.owner:
        return 'Owner';
      case OrganizationRole.admin:
        return 'Admin';
      case OrganizationRole.member:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    final label = _getRoleLabel(role);

    if (!isInteractive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return PopupMenuButton<OrganizationRole>(
      initialValue: role,
      onSelected: onRoleSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder:
          (context) => [
            _buildMenuItem(OrganizationRole.owner),
            _buildMenuItem(OrganizationRole.admin),
            _buildMenuItem(OrganizationRole.member),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<OrganizationRole> _buildMenuItem(OrganizationRole r) {
    final color = _getRoleColor(r);
    final label = _getRoleLabel(r);
    final isSelected = r == role;

    return PopupMenuItem<OrganizationRole>(
      value: r,
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check, size: 18, color: color)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : null,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
