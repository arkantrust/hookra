import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/organizations/organizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static GoRoute route() {
    return GoRoute(path: '/', builder: (context, state) => const OrganizationsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return const OrganizationsScreen();
  }
}
