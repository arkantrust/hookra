import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/authentication/authentication.dart';
import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/app/theme.dart';
import 'package:hookra/src/app/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthenticationRepository>(
          create: (_) => sl<AuthenticationRepository>(),
          dispose: (repo) => repo.dispose(),
        ),
        RepositoryProvider<UserRepository>(
          create: (_) => sl<UserRepository>(),
          dispose: (repo) => repo.dispose(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => sl<AuthenticationBloc>()..add(AuthenticationSubscriptionRequested()),
          ),
          BlocProvider(
            create:
                (context) =>
                    sl<LocationPermissionBloc>()..add(const LocationPermissionCheckRequested()),
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              title: 'Triangul8',
              debugShowCheckedModeBanner: false,
              theme: darkTheme,
              routerConfig:
                  AppRouter(
                    auth: context.read<AuthenticationBloc>(),
                    location: context.read<LocationPermissionBloc>(),
                  ).router,
            );
          },
        ),
      ),
    );
  }
}
