import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteLinkDialog extends StatelessWidget {
  final String inviteLink;

  const InviteLinkDialog({super.key, required this.inviteLink});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link de invitación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comparte este link con el usuario que quieres invitar.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              inviteLink,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: inviteLink));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copiado al portapapeles')),
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
