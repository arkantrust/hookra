import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDataSource {
  Future<void> saveProfile(Map<String, dynamic> data) async {
    await Supabase.instance.client.from('profiles').upsert(data);
  }
}
