import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/profile/profile.dart';

class SupabaseOrganizationRepository extends OrganizationRepository {
  SupabaseOrganizationRepository({
    required SupabaseClient supabase,
    required UserRepository userRepository,
  }) : _supabase = supabase,
       _userRepository = userRepository;

  final SupabaseClient _supabase;
  final UserRepository _userRepository;

  static OrganizationRole _parseMemberRole(String? role) {
    switch (role) {
      case 'owner':
        return OrganizationRole.owner;
      case 'admin':
        return OrganizationRole.admin;
      default:
        return OrganizationRole.member;
    }
  }

  static String _roleToString(OrganizationRole role) {
    switch (role) {
      case OrganizationRole.owner:
        return 'owner';
      case OrganizationRole.admin:
        return 'admin';
      case OrganizationRole.member:
        return 'member';
    }
  }

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
        role: _parseMemberRole(row['role'] as String?),
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
  Future<void> addMember(
    String organizationId,
    String profileId,
    String role,
  ) async {
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
        await _supabase
            .from('organizations')
            .select()
            .eq('id', organizationId)
            .maybeSingle();
    if (res == null) return null;
    return Organization.fromJson(res);
  }

  @override
  Future<void> updateOrganizationName(
    String organizationId,
    String name,
  ) async {
    await _supabase
        .from('organizations')
        .update({'name': name})
        .eq('id', organizationId);
  }

  @override
  Future<List<MemberWithProfile>> getOrganizationMembers(
    String organizationId,
  ) async {
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
        role: _parseMemberRole(row['role'] as String?),
      );
    }).toList();
  }

  @override
  Future<void> updateMemberRole(
    String organizationId,
    String profileId,
    OrganizationRole newRole,
  ) async {
    await _supabase
        .from('organization_members')
        .update({'role': _roleToString(newRole)})
        .eq('organization_id', organizationId)
        .eq('profile_id', profileId);
  }
}
