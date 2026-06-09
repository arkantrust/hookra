import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:hookra/firebase_options.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/app/app.dart';

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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  try {
    await dotenv.load(fileName: '.env');
    // Configures a default FirebaseApp so the transitively-pulled firebase_auth
    // iOS plugin doesn't crash on deep links. Hookra uses Supabase, not Firebase
    // — see lib/firebase_options.dart.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initSupabase();
    initServiceLocator();
    runApp(const App());
    FlutterNativeSplash.remove();
  } catch (e, s) {
    log('Startup error: $e', stackTrace: s);
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error de inicio: $e'))),
      ),
    );
  }
}
