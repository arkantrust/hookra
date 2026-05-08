import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/features/organizations/domain/model/organization.dart';
import 'package:hookra/features/organizations/domain/model/organization_member.dart';

class OrganizationDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getOrganizationsForUser(String profileId) async {
    final response = await _client
        .from('organization_members')
        .select('''
          organization:organizations(
            id,
            name,
            slug,
            owner_id,
            created_at
          ),
          role
        ''')
        .eq('profile_id', profileId);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Organization> createOrganization({
    required String name,
    required String slug,
    required String ownerId,
  }) async {
    final response = await _client
        .from('organizations')
        .insert({
          'name': name,
          'slug': slug,
          'owner_id': ownerId,
        })
        .select()
        .single();
    
    return Organization.fromJson(response);
  }

  Future<void> addMember({
    required String organizationId,
    required String profileId,
    required OrganizationRole role,
  }) async {
    final existing = await _client
        .from('organization_members')
        .select()
        .eq('organization_id', organizationId)
        .eq('profile_id', profileId)
        .maybeSingle();
    
    if (existing != null) {
      return;
    }
    
    await _client.from('organization_members').insert({
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': role == OrganizationRole.owner ? 'owner' : 'member',
    });
  }

  Future<List<String>> getExistingSlugs() async {
    final response = await _client
        .from('organizations')
        .select('slug')
        .select();
    
    return List<String>.from(response.map((e) => e['slug'] as String));
  }

  Future<Map<String, dynamic>?> getOrganizationById(String organizationId) async {
    final response = await _client
        .from('organizations')
        .select()
        .eq('id', organizationId)
        .maybeSingle();
    
    return response;
  }

  Future<void> updateOrganizationName(String organizationId, String name) async {
    await _client
        .from('organizations')
        .update({'name': name})
        .eq('id', organizationId);
  }

  Future<List<Map<String, dynamic>>> getOrganizationMembers(String organizationId) async {
    final response = await _client
        .from('organization_members')
        .select('''
          profile:profiles!organization_members_profile_id_fkey(
            id,
            first_name,
            last_name,
            email
          ),
          role
        ''')
        .eq('organization_id', organizationId);
    
    return List<Map<String, dynamic>>.from(response);
  }
}