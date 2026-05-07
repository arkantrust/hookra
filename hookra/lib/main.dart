import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uni_links/uni_links.dart';

import 'package:hookra/src/config/supabase.dart';
import 'package:hookra/features/auth/ui/bloc/login_bloc.dart';
import 'package:hookra/features/auth/ui/bloc/signup_bloc.dart';
import 'package:hookra/features/auth/ui/screens/login_screen.dart';
import 'package:hookra/features/auth/ui/screens/signup_screen.dart';
import 'package:hookra/features/auth/ui/screens/forgot_password_screen.dart';
import 'package:hookra/features/auth/ui/screens/reset_password_screen.dart';
import 'package:hookra/features/home/ui/screens/home_screen.dart';

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

class HookraApp extends StatefulWidget {
  const HookraApp({super.key});

  @override
  State<HookraApp> createState() => _HookraAppState();
}

class _HookraAppState extends State<HookraApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    // Handle the initial link if the app was launched from a deep link.
    _handleInitialUri();
    // Listen to incoming links while the app is running.
    _sub = uriLinkStream.listen((uri) {
      _handleUri(uri);
    }, onError: (err) {
      // ignore
    });
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      _handleUri(uri);
    } catch (e) {
      // ignore
    }
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    // Example deep link: hookra://reset-password
    if (uri.path.contains('reset-password')) {
      // Pass the full uri as an argument in case it's needed.
      _navigatorKey.currentState?.pushNamed('/reset-password', arguments: uri.toString());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hookra',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => BlocProvider(
              create: (_) => LoginBloc(),
              child: const LoginScreen(),
            ),
        '/signup': (_) => BlocProvider(
              create: (_) => SignupBloc(),
              child: const SignupScreen(),
            ),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
