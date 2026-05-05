import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:hookra/src/config/supabase.dart';
import 'package:hookra/features/auth/ui/bloc/login_bloc.dart';
import 'package:hookra/features/auth/ui/bloc/signup_bloc.dart';
import 'package:hookra/features/auth/ui/screens/login_screen.dart';
import 'package:hookra/features/auth/ui/screens/signup_screen.dart';
import 'package:hookra/features/home/ui/screens/home_screen.dart';
import 'package:hookra/features/organization_roles/ui/bloc/organization_roles_bloc.dart';
import 'package:hookra/features/organization_roles/ui/screens/organization_roles_screen.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  try {
    await dotenv.load(fileName: '.env');
    await initSupabase();
    runApp(const HookraApp());
  } catch (e, s) {
    log('Startup error: $e', stackTrace: s);
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

class HookraApp extends StatelessWidget {
  const HookraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hookra',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login':
            (_) => BlocProvider(
              create: (_) => LoginBloc(),
              child: const LoginScreen(),
            ),
        '/signup':
            (_) => BlocProvider(
              create: (_) => SignupBloc(),
              child: const SignupScreen(),
            ),
        '/home': (_) => const HomeScreen(),
        '/organization/roles':
            (_) => BlocProvider(
              create:
                  (_) =>
                      OrganizationRolesBloc()..add(OrganizationRolesStarted()),
              child: const OrganizationRolesScreen(),
            ),
      },
    );
  }
}
