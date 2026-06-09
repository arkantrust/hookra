import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase configuration.
///
/// **Hookra does not use Firebase.** The `flutter_ai_toolkit` chat widget pulls
/// in `firebase_ai` -> `firebase_auth` transitively. The `firebase_auth` iOS
/// plugin registers for the UIScene `openURL` callback and calls `Auth.auth()`
/// the moment a deep link arrives (e.g. `app.ddulce.hookra://invite?token=...`).
/// With no default `FirebaseApp` configured that call hits an assertion and the
/// app crashes before `app_links` can route the invite.
///
/// Initializing Firebase with these placeholder values creates a default app so
/// `Auth.auth()` returns normally and the plugin simply ignores our non-Firebase
/// URL. No Firebase services are used and no network calls are made — these
/// values intentionally do not point at a real Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _placeholder;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        return _placeholder;
    }
  }

  static const _ios = FirebaseOptions(
    apiKey: 'AIzaSyHookraUnusedPlaceholderKey0000000',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'hookra-unused',
    iosBundleId: 'app.ddulce.hookra',
  );

  static const _android = FirebaseOptions(
    apiKey: 'AIzaSyHookraUnusedPlaceholderKey0000000',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'hookra-unused',
  );

  static const _placeholder = FirebaseOptions(
    apiKey: 'AIzaSyHookraUnusedPlaceholderKey0000000',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'hookra-unused',
  );
}
