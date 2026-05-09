import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationDataSource _dataSource;
  final SupabaseClient _client = Supabase.instance.client;

  OrganizationRepositoryImpl(this._dataSource);

  @override
  Future<List<OrganizationMember>> getMembers(String organizationId) {
    return _dataSource.getMembers(organizationId);
  }

  @override
  Future<Organization?> getOrganization(String organizationId) {
    return _dataSource.getOrganization(organizationId);
  }

  @override
  Future<OrganizationMember?> getMemberRole(
      String organizationId, String profileId) {
    return _dataSource.getMemberRole(organizationId, profileId);
  }

  @override
  Future<void> updateMemberRole(String memberId, OrgRole newRole) {
    return _dataSource.updateMemberRole(memberId, newRole);
  }

  @override
  Future<Organization?> getUserOrganization(String profileId) {
    return _dataSource.getUserOrganization(profileId);
  }

  @override
  Future<List<Organization>> getUserOrganizations(String profileId) {
    return _dataSource.getUserOrganizations(profileId);
  }

  // CRUD methods - stub implementations (not fully implemented in data source)
  @override
  Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _client
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
        .eq('profile_id', userId);

    final results = List<Map<String, dynamic>>.from(res);

    return results.map((row) {
      final orgData = row['organization'] as Map<String, dynamic>;
      return OrganizationWithRole(
        organization: Organization.fromJson(orgData),
        role: row['role'] == 'owner' ? OrganizationRole.owner : 
              row['role'] == 'admin' ? OrganizationRole.admin : 
              OrganizationRole.member,
      );
    }).toList();
  }

  @override
  Future<Organization> createOrganization(String name, String ownerId) async {
    final slug = await generateUniqueSlug(name);
    
    final response = await _client
        .from('organizations')
        .insert({'name': name, 'slug': slug, 'owner_id': ownerId})
        .select()
        .single();
    
    return Organization.fromJson(response);
  }

  @override
  Future<void> addMember(String organizationId, String profileId, String role) async {
    final existing = await _client
        .from('organization_members')
        .select()
        .eq('organization_id', organizationId)
        .eq('profile_id', profileId)
        .maybeSingle();

    if (existing != null) return;

    await _client.from('organization_members').insert({
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': role,
    });
  }

  @override
  Future<String> generateUniqueSlug(String baseName) async {
    if (baseName.isEmpty) {
      baseName = 'org-\${DateTime.now().millisecondsSinceEpoch}';
    }
    return baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  @override
  Future<Organization?> getOrganizationById(String organizationId) {
    return _dataSource.getOrganization(organizationId);
  }

  @override
  Future<void> updateOrganizationName(String organizationId, String name) async {
    await _client
        .from('organizations')
        .update({'name': name})
        .eq('id', organizationId);
  }

  @override
  Future<List<MemberWithProfile>> getOrganizationMembers(String organizationId) async {
    final members = await _dataSource.getMembers(organizationId);
    return members.map((m) => MemberWithProfile(
      profileId: m.profileId,
      firstName: m.profile?.firstName ?? '',
      lastName: m.profile?.lastName ?? '',
      email: m.profile?.email ?? '',
      role: m.role == OrgRole.owner ? OrganizationRole.owner : 
            m.role == OrgRole.admin ? OrganizationRole.admin : 
            OrganizationRole.member,
    )).toList();
  }
}