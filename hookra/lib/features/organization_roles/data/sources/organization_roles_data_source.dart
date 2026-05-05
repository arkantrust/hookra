import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationRolesDataSource {
  OrganizationRolesDataSource({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> getCurrentMembership(String profileId) async {
    final row =
        await _supabase
            .from('organization_members')
            .select('organization_id, role')
            .eq('profile_id', profileId)
            .limit(1)
            .maybeSingle();

    if (row == null) {
      throw StateError('El usuario no pertenece a ninguna organización');
    }

    return Map<String, dynamic>.from(row as Map);
  }

  Future<List<Map<String, dynamic>>> getOrganizationMembersRows(
    String organizationId,
  ) async {
    final rows = await _supabase
        .from('organization_members')
        .select('organization_id, profile_id, role')
        .eq('organization_id', organizationId);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> getProfilesByIds(
    List<String> profileIds,
  ) async {
    if (profileIds.isEmpty) {
      return const {};
    }

    final rows = await _supabase
        .from('profiles')
        .select('id, first_name, last_name, email')
        .inFilter('id', profileIds);

    final profiles = <String, Map<String, dynamic>>{};
    for (final row in (rows as List)) {
      final profile = Map<String, dynamic>.from(row as Map);
      final id = (profile['id'] ?? '').toString();
      if (id.isNotEmpty) {
        profiles[id] = profile;
      }
    }

    return profiles;
  }

  Future<void> updateMemberRole({
    required String organizationId,
    required String profileId,
    required String role,
  }) async {
    await _supabase
        .from('organization_members')
        .update({'role': role})
        .eq('organization_id', organizationId)
        .eq('profile_id', profileId);
  }
}
