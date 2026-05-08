import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static GoRoute route() {
    return GoRoute(path: '/', builder: (context, state) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Gestionar roles',
            onPressed: () => context.go('/organization/roles'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              children: [
                const TextSpan(text: "We're still working on this, in the meantime visit our "),
                TextSpan(
                  text: 'website',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap =
                            () => launchUrl(
                              Uri.parse('https://hookra.ddulce.app'),
                              mode: LaunchMode.externalApplication,
                            ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
