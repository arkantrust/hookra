import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/app/main_layout.dart';

import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/profile/profile.dart';

class AuthRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  AuthRefreshStream(AuthBloc auth) {
    _subscription = auth.stream.asBroadcastStream().listen((data) => notifyListeners());
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

        final isAuthenticated = auth.state.status == AuthStatus.authenticated;

        // If not authenticated and not going to auth, redirect to auth
        if (!isAuthenticated && !goingToAuth) return SignInPage.route().path;

        // If authenticated and going to auth, redirect to home
        if (isAuthenticated && goingToAuth) return HomePage.route().path;

        return null;
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            HomePage.route(), // route: /
            ProfilePage.route(), // route: /profile
          ],
        ),
        SignInPage.route(), // route: /auth/sign-in
        SignUpPage.route(), // route: /auth/sign-up
        ForgotPasswordPage.route(), // route: /auth/forgot-password
        ResetPasswordPage.route(), // route: /auth/reset-password
      ],
      errorBuilder:
          (context, state) => SafeArea(
            child: Scaffold(body: Center(child: Text('Error: ${state.error}')))
          ),
    );
  }
}
