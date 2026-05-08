import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/profile/domain/failures/user_failure.dart';
import 'package:hookra/src/profile/domain/repo/user_repository.dart';
import 'package:hookra/src/utils/network.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template supabase_user_repository}
/// Repository which fetches the current user's profile from Supabase.
///
/// Caches the resulting [User] in memory until [dispose] is called.
/// {@endtemplate}
final class SupabaseUserRepository extends UserRepository {
  SupabaseUserRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  User? _user;

  @override
  Future<Result<User>> getUser() async {
    if (_user != null) return Result.success(_user!);

    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return Result.failure(const UserNotFound());

    Map<String, dynamic>? data = {};
    try {
      data =
          await _supabase
              .from('profiles')
              .select('id, first_name, last_name, email, avatar_url')
              .eq('id', supabaseUser.id)
              .maybeSingle();
    } on PostgrestException {
      final connected = await hasInternetAccess();
      if (!connected) {
        return Result.failure(const NoInternetConnection());
      } else {
        return Result.failure(const ServerUnreachable());
      }
    } catch (e, s) {
      return Result.unknown(name: 'SupabaseUserRepository', error: e, stackTrace: s);
    }

    if (data == null || data.isEmpty) return Result.failure(const UserNotFound());
    _user = User.fromJson(data);
    return Result.success(_user!);
  }

  @override
  Future<void> dispose() async {
    _user = null;
  }
}
