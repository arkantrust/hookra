import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Checks reachability by pinging the project's own Supabase URL.
/// Using a third-party endpoint (e.g. Google's generate_204) is unreliable
/// on Android emulators and proves nothing about whether Supabase is reachable.
Future<bool> hasInternetAccess() async {
  final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
  if (supabaseUrl.isEmpty) return false;
  return isReachable(supabaseUrl);
}

Future<bool> isReachable(String url) async {
  try {
    final uri = Uri.parse(url);
    final request = await HttpClient()
        .getUrl(uri)
        .timeout(const Duration(seconds: 5));
    final response = await request.close().timeout(const Duration(seconds: 5));
    return response.statusCode < 500;
  } catch (_) {
    return false;
  }
}

class NoInternetConnection implements Exception {
  const NoInternetConnection();
}

class ServerUnreachable implements Exception {
  const ServerUnreachable();
}
