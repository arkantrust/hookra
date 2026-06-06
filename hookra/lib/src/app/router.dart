import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/app/main_layout.dart';

import 'package:hookra/src/ai_chat/ai_chat.dart';
import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/settings/settings.dart';

class AuthRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  AuthRefreshStream(AuthBloc auth) {
    _subscription = auth.stream.asBroadcastStream().listen(
      (data) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthBloc auth;

  late final GoRouter router;

  AppRouter({required this.auth}) {
    router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: AuthRefreshStream(auth),
      redirect: (context, state) {
        // Routes under /auth/* are the unauthenticated flow.
        final goingToAuth = state.matchedLocation.startsWith('/auth');
        // /invite is publicly accessible — users can view invite details without auth.
        final goingToInvite = state.matchedLocation.startsWith('/invite');

        final isAuthenticated = auth.state.status == AuthStatus.authenticated;

        // If not authenticated and not going to auth, redirect to auth
        if (!isAuthenticated && !goingToAuth && !goingToInvite) {
          return SignInPage.route().path;
        }

        // If authenticated and going to auth, redirect to home
        if (isAuthenticated && goingToAuth) return HomePage.route().path;
        return null; // Needed for this function
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            HomePage.route(), // route: /
            ProfilePage.route(), // route: /profile
            OrganizationsPage.route(), // route: /organizations
          ],
        ),
        // Detail pages live outside the shell — they are full-screen without the
        // bottom navigation bar, but still protected by the top-level redirect.
        OrganizationDetailsPage.route(), // route: /organizations/:id
        AcceptInvitePage.route(), // route: /invite?token=
        AiChatPage.route(), // route: /content/:contentId/chat
        EditProfilePage.route(), // route: /settings/edit-profile
        SignInPage.route(), // route: /auth/sign-in
        SignUpPage.route(), // route: /auth/sign-up
      ],
      errorBuilder:
          (context, state) => SafeArea(
            child: Scaffold(body: Center(child: Text('Error: ${state.error}'))),
          ),
    );
  }
}
