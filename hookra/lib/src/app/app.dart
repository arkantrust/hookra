import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/selection/selection.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/app/theme.dart';
import 'package:hookra/src/app/router.dart';

class App extends StatelessWidget {
  const App({super.key});

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
        RepositoryProvider<OrganizationRepository>(
          create: (_) => sl<OrganizationRepository>(),
          dispose: (repo) => repo.dispose(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                sl<AuthBloc>()..add(AuthSubscriptionRequested()),
          ),
          BlocProvider<SelectionCubit>.value(value: sl<SelectionCubit>()),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final AppRouter _appRouter;
  StreamSubscription<String>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(auth: context.read<AuthBloc>());
    _initDeepLinks();
  }

  void _initDeepLinks() {
    final appLinks = AppLinks();
    _linkSub = appLinks.stringLinkStream.listen(
      (link) => WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) _handleLink(link); },
      ),
    );
  }

  void _handleLink(String link) {
    final uri = Uri.parse(link);
    if (uri.host == 'invite') {
      final token = uri.queryParameters['token'];
      if (token != null) _appRouter.router.go('/invite?token=$token');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context.read<SelectionCubit>().clear();
        }
      },
      child: MaterialApp.router(
        title: 'Hookra',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
