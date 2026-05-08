import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uni_links/uni_links.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

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
  String? _lastHandledUri;

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

  void _handleUri(Uri? uri) async {
    if (uri == null) return;
    // Avoid double-processing the same URI (cold-start + stream may both fire).
    final uriString = uri.toString();
    if (_lastHandledUri != null && _lastHandledUri == uriString) return;
    _lastHandledUri = uriString;

    // Parse both query parameters and fragment parameters.
    // Prefer query parameters (they survive across Android intents) and
    // use fragment as a fallback.
    final Map<String, String> params = {};
    if (uri.fragment.isNotEmpty) {
      try {
        params.addAll(Uri.splitQueryString(uri.fragment));
      } catch (_) {
        // ignore malformed fragment
      }
    }
    // Add query parameters last so they override fragment values when present.
    params.addAll(uri.queryParameters);

    // Detect common Supabase recovery tokens
    final hasAccessToken = params.containsKey('access_token');
    final hasRefreshToken = params.containsKey('refresh_token');
    final flowType = params['type'] ?? '';

    // Safe debug logs (do NOT print tokens!)
    // Log presence of tokens and where they were found.
    final foundWhere = <String>[];
    if (uri.queryParameters.isNotEmpty) foundWhere.add('query');
    if (uri.fragment.isNotEmpty) foundWhere.add('fragment');
    // Example: "Deep link received (found in: query,fragment)"
    // Using debugPrint avoids accidental long-term logging.
    debugPrint('Deep link received (found in: ${foundWhere.join(',')})');

    // We only process Supabase recovery links (type=recovery)
    if (uri.path.contains('reset-password') && flowType == 'recovery' && (hasAccessToken || hasRefreshToken)) {
      // Prefer to exchange refresh token for fresh access token when possible.
      String? accessToken = params['access_token'];
      String? refreshToken = params['refresh_token'];

      // If we have a refresh token, try to exchange it for a session with Supabase REST token endpoint.
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final exchanged = await _exchangeRefreshToken(refreshToken);
          if (exchanged != null && exchanged['access_token'] != null) {
            accessToken = exchanged['access_token'];
            refreshToken = exchanged['refresh_token'] ?? refreshToken;
            debugPrint('Recovered session from refresh token (exchange succeeded).');
          } else {
            debugPrint('Refresh token exchange failed.');
          }
        } catch (e) {
          debugPrint('Refresh token exchange error: $e');
        }
      }

      // If we have an access token we can proceed to the reset screen and pass it via arguments.
      if (accessToken != null && accessToken.isNotEmpty) {
        // Pass tokens in-memory via Navigator arguments (do NOT persist them).
        _navigatorKey.currentState?.pushNamed(
          '/reset-password',
          arguments: {'access_token_present': true},
        );
        // Store the raw token in a short-lived in-memory holder inside the AuthDataSource
        // so the ResetPasswordScreen can use it without serializing to disk.
        // We DO NOT log the token itself.
        AuthTokenHolder.instance.setTokens(accessToken: accessToken, refreshToken: refreshToken);
        return;
      }
    }

    // If we reach here, push reset-password but without tokens; screen will show invalid/expired.
    if (uri.path.contains('reset-password')) {
      _navigatorKey.currentState?.pushNamed('/reset-password', arguments: {'access_token_present': false});
    }
  }

  Future<Map<String, dynamic>?> _exchangeRefreshToken(String refreshToken) async {
    try {
      final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
      final anonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
      if (supabaseUrl.isEmpty || anonKey.isEmpty) return null;

      final uri = Uri.parse(supabaseUrl).replace(path: '/auth/v1/token');

      final body = 'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(refreshToken)}';
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.headers.set('apikey', anonKey);
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      httpClient.close(force: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json;
      } else {
        return null;
      }
    } catch (e) {
      return null;
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
