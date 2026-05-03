import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/app/main_layout.dart';

import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/authentication/authentication.dart';
import 'package:hookra/src/profile/profile.dart';

class AuthenticationRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  AuthenticationRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthenticationBloc auth;

  final LocationPermissionBloc location;

  late final GoRouter router;

  AppRouter({required this.auth, required this.location}) {
    router = GoRouter(
      initialLocation: '/auth',
      debugLogDiagnostics: true,
      refreshListenable: AuthenticationRefreshStream(auth.stream),
      redirect: (context, state) {
        // The route is /auth/* (e.g., /auth/sign-in, /auth/sign-up, etc.)
        final goingToAuth = state.matchedLocation.startsWith('/auth/');
        final goingToPermissions = state.matchedLocation == LocationPermissionPage.route().path;

        final isAuthenticated = auth.state.status == AuthenticationStatus.authenticated;

        // If not authenticated and not going to auth, redirect to auth
        if (!isAuthenticated && !goingToAuth) return SignInPage.route().path;

        // If authenticated and not going to permissions, check location permissions
        if (isAuthenticated && !goingToPermissions) {
          if (location.state.status == LocationPermissionStatus.checking) {
            return '/splash'; // Show splash while checking permissions
          }

          if (location.state.status == LocationPermissionStatus.granted) {
            return null; // Allow navigation if permission is granted
          }

          // Redirect to permissions if not granted
          return LocationPermissionPage.route().path;
        }

        return null;
      },
      routes: [
        LocationPermissionPage.route(), // route: /permissions/location
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            HomePage.route(), // route: /
            ProfilePage.route(), // route: /profile
          ],
        ),
        SignInPage.route(), // route: /auth/sign-in
        SignUpPage.route(), // route: /auth/sign-up
        GoRoute(
          path: '/splash',
          builder: (context, state) {
            return SafeArea(child: Scaffold(body: Center(child: CircularProgressIndicator())));
          },
        ),
        GoRoute(
          path: '/auth',
          redirect: (context, state) {
            final authStatus = context.read<AuthenticationBloc>().state.status;
            return switch (authStatus) {
              AuthenticationStatus.unknown =>
                '/splash', // Wait for the authentication status to be determined
              AuthenticationStatus.unauthenticated => SignInPage.route().path,
              AuthenticationStatus.authenticated => LocationPermissionPage.route().path,
            };
          },
        ),
      ],
      errorBuilder:
          (context, state) =>
              SafeArea(child: Scaffold(body: Center(child: Text('Error: ${state.error}')))),
    );
  }
}
