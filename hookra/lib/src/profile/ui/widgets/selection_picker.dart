import 'package:flutter/material.dart';

/// Shows a modal bottom sheet listing [items] and returns the id of the chosen
/// one (or null if dismissed). The current selection is marked with a check.
Future<String?> showSelectionPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String? selectedId,
  required String Function(T) idOf,
  required String Function(T) labelOf,
}) {
  final palette = Theme.of(context).colorScheme;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
                  ),
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Text(
                  'No hay elementos disponibles',
                  style: TextStyle(color: palette.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = idOf(item);
                    final isSelected = id == selectedId;
                    return ListTile(
                      title: Text(
                        labelOf(item),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected ? palette.primary : palette.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: palette.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(id),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
