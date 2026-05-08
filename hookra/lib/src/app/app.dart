import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/app/theme.dart';
import 'package:hookra/src/app/router.dart';

class App extends StatelessWidget {
  /// Optional navigator key forwarded to GoRouter. Provided by [HookraApp]
  /// so the deep link handler can call GoRouter.of(context).go(...).
  final GlobalKey<NavigatorState>? navigatorKey;

  const App({super.key, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => sl<AuthRepository>(),
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
            create: (context) => sl<AuthBloc>()..add(AuthSubscriptionRequested()),
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              title: 'Hookra',
              debugShowCheckedModeBanner: false,
              theme: darkTheme,
              routerConfig: AppRouter(
                auth: context.read<AuthBloc>(),
                navigatorKey: navigatorKey,
              ).router,
            );
          },
        ),
      ),
    );
  }
}
