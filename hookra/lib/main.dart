import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_links/uni_links.dart';

import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/config/auth_token_holder.dart';
import 'package:hookra/src/app/app.dart';
import 'package:hookra/src/auth/auth.dart';

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
    initServiceLocator();
    runApp(const HookraApp());
  } catch (e, s) {
    log('Startup error: $e', stackTrace: s);
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error de inicio: $e'))),
      ),
    );
  }
}

/// Thin stateful wrapper around [App].
///
/// Sole responsibility: intercept Supabase password-recovery deep links,
/// extract tokens into [AuthTokenHolder], and navigate to the reset-password
/// screen via GoRouter. All actual app logic lives in [App].
class HookraApp extends StatefulWidget {
  const HookraApp({super.key});

  @override
  State<HookraApp> createState() => _HookraAppState();
}

class _HookraAppState extends State<HookraApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _sub;
  String? _lastHandledUri;
  String? _pendingRoute; // For cold-start: navigate after first frame

  @override
  void initState() {
    super.initState();
    _handleInitialUri();
    _sub = uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {/* ignore link errors */},
    );
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      _handleUri(uri);
    } catch (_) {/* ignore */}
  }

  void _handleUri(Uri? uri) async {
    if (uri == null) return;

    // Deduplicate: cold-start + foreground stream may both fire the same URI.
    final uriString = uri.toString();
    if (_lastHandledUri == uriString) return;
    _lastHandledUri = uriString;

    // Parse both query parameters (survive Android intents) and
    // fragment parameters (Supabase implicit flow fallback).
    final Map<String, String> params = {};
    if (uri.fragment.isNotEmpty) {
      try {
        params.addAll(Uri.splitQueryString(uri.fragment));
      } catch (_) {/* ignore malformed fragment */}
    }
    // Query params take precedence over fragment params.
    params.addAll(uri.queryParameters);

    final hasAccessToken = params.containsKey('access_token');
    final hasRefreshToken = params.containsKey('refresh_token');
    final flowType = params['type'] ?? '';

    // Safe debug log — never print token values.
    final foundIn = <String>[];
    if (uri.queryParameters.isNotEmpty) foundIn.add('query');
    if (uri.fragment.isNotEmpty) foundIn.add('fragment');
    debugPrint('Deep link received (params found in: ${foundIn.join(',')})');

    // Only handle Supabase password-recovery links.
    if (uri.path.contains('reset-password') &&
        flowType == 'recovery' &&
        (hasAccessToken || hasRefreshToken)) {
      String? accessToken = params['access_token'];
      final String? refreshToken = params['refresh_token'];

      // Try to exchange refresh token for a fresh access token when possible.
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final repo = sl<AuthRepository>();
          final exchanged = await repo.exchangeRefreshToken(refreshToken);
          if (exchanged != null && exchanged['access_token'] != null) {
            accessToken = exchanged['access_token'] as String;
            debugPrint('Deep link: refresh token exchanged successfully.');
          } else {
            debugPrint('Deep link: refresh token exchange returned no result.');
          }
        } catch (e) {
          debugPrint('Deep link: refresh token exchange error: $e');
        }
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        // Store token in-memory only — never logged, never persisted to disk.
        AuthTokenHolder.instance.setTokens(
          accessToken: accessToken,
        );
        _navigateTo(ResetPasswordPage.route().path);
        return;
      }
    }

    // Deep link is for reset-password but has no valid tokens → navigate anyway;
    // the ResetPasswordBloc will surface an expired-token error.
    if (uri.path.contains('reset-password')) {
      _navigateTo(ResetPasswordPage.route().path);
    }
  }

  /// Navigate via GoRouter. Guards against the case where the router has not
  /// yet been attached to the widget tree (cold-start timing).
  void _navigateTo(String path) {
    final ctx = _navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(path);
    } else {
      // Router not ready yet — defer to after the first frame.
      _pendingRoute = path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final deferredCtx = _navigatorKey.currentContext;
        if (deferredCtx != null && deferredCtx.mounted && _pendingRoute != null) {
          GoRouter.of(deferredCtx).go(_pendingRoute!);
          _pendingRoute = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Delegate everything to App — this widget only manages deep links.
    return App(navigatorKey: _navigatorKey);
  }
}
