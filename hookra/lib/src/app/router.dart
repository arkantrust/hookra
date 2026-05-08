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

  AppRouter({
    required this.auth,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: AuthRefreshStream(auth),
      redirect: (context, state) {
        // Routes under /auth/* are the unauthenticated flow.
        final goingToAuth = state.matchedLocation.startsWith('/auth');

        final isAuthenticated = auth.state.status == AuthStatus.authenticated;

        // If not authenticated and not going to auth, redirect to auth
        if (!isAuthenticated && !goingToAuth) return SignInPage.route().path;

        // If authenticated and going to sign-in or sign-up, redirect to home.
        // Allow /auth/forgot-password and /auth/reset-password even when authenticated
        // in case a user navigates to those via deep link while logged in.
        final goingToSignInOrUp = state.matchedLocation == SignInPage.route().path ||
            state.matchedLocation == SignUpPage.route().path;
        if (isAuthenticated && goingToSignInOrUp) return HomePage.route().path;

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
      errorBuilder: (context, state) =>
          SafeArea(child: Scaffold(body: Center(child: Text('Error: ${state.error}')))),
    );
  }
}
