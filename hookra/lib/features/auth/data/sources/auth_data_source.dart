import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDataSource {
  Future<AuthResponse> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName, 'last_name': lastName},
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
