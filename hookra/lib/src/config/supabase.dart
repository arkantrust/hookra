import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> initSupabase() async {
  var url = dotenv.get('SUPABASE_URL', fallback: '');
  var publishableKey = dotenv.get('SUPABASE_PUBLISHABLE_KEY', fallback: '');
  if (url.isEmpty || publishableKey.isEmpty) {
    throw Exception('Supabase URL and Publishable Key must be provided');
  }

  await Supabase.initialize(
    url: url,
    anonKey: publishableKey, // We're now using assymetric JWTs but the parameter name is still anonKey for backward compatibility
  );
}

