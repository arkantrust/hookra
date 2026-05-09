import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';

class SupabaseOrganizationRepository extends OrganizationRepository {
  SupabaseOrganizationRepository({
    required SupabaseClient supabase,
    required UserRepository userRepository,
  }) : _supabase = supabase,
       _userRepository = userRepository;

  final SupabaseClient _supabase;
  final UserRepository _userRepository;

  @override
  Future<List<OrganizationMember>> getMembers(String organizationId) async {
    final res = await _supabase
        .from('organization_members')
        .select('''
          id,
          organization_id,
          profile_id,
          role,
          invited_by,
          joined_at
        ''')
        .eq('organization_id', organizationId)
        .order('joined_at', ascending: true);

    final List<OrganizationMember> members = [];
    for (final memberJson in res) {
      final profileId = memberJson['profile_id'] as String;
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();

      User? user;
      if (profileResponse != null) {
        user = User(
          id: profileResponse['id'] as String,
          firstName: profileResponse['first_name'] as String,
          lastName: profileResponse['last_name'] as String,
          email: profileResponse['email'] as String,
        );
      }

      final member = OrganizationMember.fromJson(memberJson).copyWith(
        profile: user,
      );
      members.add(member);
    }
    return members;
  }

  @override
  Future<Organization?> getOrganization(String organizationId) async {
    final res = await _supabase
        .from('organizations')
        .select()
        .eq('id', organizationId)
        .maybeSingle();
    if (res == null) return null;
    return Organization.fromJson(res);
  }

  @override
  Future<OrganizationMember?> getMemberRole(String organizationId, String profileId) async {
    final res = await _supabase
        .from('organization_members')
        .select()
        .eq('organization_id', organizationId)
        .eq('profile_id', profileId)
        .maybeSingle();
    if (res == null) return null;
    return OrganizationMember.fromJson(res);
  }

  @override
  Future<void> updateMemberRole(String memberId, OrgRole newRole) async {
    await _supabase
        .from('organization_members')
        .update({'role': newRole.value})
        .eq('id', memberId);
  }

  @override
  Future<Organization?> getUserOrganization(String profileId) async {
    final memberResponse = await _supabase
        .from('organization_members')
        .select('organization_id')
        .eq('profile_id', profileId)
        .limit(1)
        .maybeSingle();

    if (memberResponse == null) return null;

    final orgId = memberResponse['organization_id'];
    final orgResponse = await _supabase
        .from('organizations')
        .select()
        .eq('id', orgId)
        .maybeSingle();

    if (orgResponse == null) return null;
    return Organization.fromJson(orgResponse);
  }

  @override
  Future<List<Organization>> getUserOrganizations(String profileId) async {
    final memberResponse = await _supabase
        .from('organization_members')
        .select('organization_id')
        .eq('profile_id', profileId);

    if (memberResponse.isEmpty) return [];

    final orgIds = memberResponse.map((m) => m['organization_id'] as String).toList();

    final List<Organization> organizations = [];
    for (final orgId in orgIds) {
      final orgResponse = await _supabase
          .from('organizations')
          .select()
          .eq('id', orgId)
          .maybeSingle();
      if (orgResponse != null) {
        organizations.add(Organization.fromJson(orgResponse));
      }
    }
    return organizations;
  }

  // End of role management methods

  @override
  Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser() async {
    final user = await _userRepository.getUser();
    if (user.isFailure) {
      throw Exception('Failed to get current user');
    }

    final profileId = user.value.id;
    final res = await _supabase
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

    final results = List<Map<String, dynamic>>.from(res);

    return results.map((row) {
      final orgData = row['organization'] as Map<String, dynamic>;
      return OrganizationWithRole(
        organization: Organization.fromJson(orgData),
        role: row['role'] == 'owner' ? OrganizationRole.owner : OrganizationRole.member,
      );
    }).toList();
  }

  @override
  Future<Organization> createOrganization(String name, String ownerId) async {
    final slug = await generateUniqueSlug(name);

    final response =
        await _supabase
            .from('organizations')
            .insert({'name': name, 'slug': slug, 'owner_id': ownerId})
            .select()
            .single(); // TODO: Use maybeSingle

    return Organization.fromJson(response);
  }

  // Should receive OrganizationRole
  @override
  Future<void> addMember(String organizationId, String profileId, String role) async {
    final existing =
        await _supabase
            .from('organization_members')
            .select()
            .eq('organization_id', organizationId)
            .eq('profile_id', profileId)
            .maybeSingle();

    if (existing != null) {
      return;
    }

    await _supabase.from('organization_members').insert({
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': role,
    });
  }

  // TODO: Make sure slugs are unique
  // This function should only normalize the name, not ensure uniqueness. Uniqueness should be handled in the data source by checking existing slugs and appending a number if needed.
  // Uniqueness should be handled with atomicity in the DB
  @override
  Future<String> generateUniqueSlug(String baseName) async {
    if (baseName.isEmpty) {
      baseName = 'org-${DateTime.now().millisecondsSinceEpoch}';
    }

    return baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  @override
  Future<Organization?> getOrganizationById(String organizationId) async {
    final res =
        await _supabase.from('organizations').select().eq('id', organizationId).maybeSingle();
    if (res == null) return null;
    return Organization.fromJson(res);
  }

  @override
  Future<void> updateOrganizationName(String organizationId, String name) async {
    await _supabase.from('organizations').update({'name': name}).eq('id', organizationId);
  }

  @override
  Future<List<MemberWithProfile>> getOrganizationMembers(String organizationId) async {
    final res = await _supabase
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

    final results = List<Map<String, dynamic>>.from(res);

    return results.map((row) {
      final profile = row['profile'] as Map<String, dynamic>;
      return MemberWithProfile(
        profileId: profile['id'] as String,
        firstName: profile['first_name'] as String? ?? '',
        lastName: profile['last_name'] as String? ?? '',
        email: profile['email'] as String? ?? '',
        role: row['role'] == 'owner' ? OrganizationRole.owner : OrganizationRole.member,
      );
    }).toList();
  }
}
