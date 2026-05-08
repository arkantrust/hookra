import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> initSupabase() async {
  final url = dotenv.get('SUPABASE_URL', fallback: '');
  final anonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be provided in .env');
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
}

