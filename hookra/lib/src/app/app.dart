import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/authentication/authentication.dart';
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
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              title: 'Hookra',
              debugShowCheckedModeBanner: false,
              theme: darkTheme,
              routerConfig: AppRouter(auth: context.read<AuthenticationBloc>()).router,
            );
          },
        ),
      ),
    );
  }
}
