import 'dart:developer' as developer;

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
    // Try RPC first (uses a SECURITY DEFINER function that joins profiles)
    try {
      final rpcResult = await _supabase.rpc(
        'get_org_members_with_profiles',
        params: {'org_uuid': organizationId},
      );
      developer.log('RPC result: $rpcResult');
      if (rpcResult != null && rpcResult is List) {
        return (rpcResult as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
      }
    } catch (e, s) {
      developer.log(
        'RPC call failed or returned unexpected format: $e',
        stackTrace: s,
      );
    }

    // Fallback: plain select from organization_members
    final rows = await _supabase
        .from('organization_members')
        .select('organization_id, profile_id, role')
        .eq('organization_id', organizationId);

    developer.log('Organization members (fallback): $rows');
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

    developer.log('Profiles fetched: $rows for IDs: $profileIds');

    final profiles = <String, Map<String, dynamic>>{};
    for (final row in (rows as List)) {
      final profile = Map<String, dynamic>.from(row as Map);
      final id = (profile['id'] ?? '').toString();
      if (id.isNotEmpty) {
        profiles[id] = profile;
      }
    }

    developer.log('Profiles map: $profiles');
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
