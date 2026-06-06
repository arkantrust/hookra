import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/data/models/organization_dto.dart';
import 'package:hookra/src/organizations/domain/failures/organization_failure.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/utils/result.dart';

class SupabaseOrganizationRepository extends OrganizationRepository {
  SupabaseOrganizationRepository({
    required this._supabase,
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

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

  /// Normalizes a name into a URL-safe slug.
  /// Uniqueness enforcement must be handled at the database level
  /// via a unique constraint — this only normalizes the string.
  String _normalizeSlug(String baseName) {
    final name =
        baseName.isEmpty
            ? 'org-${DateTime.now().millisecondsSinceEpoch}'
            : baseName;
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  @override
  Future<Result<List<OrganizationWithRole>>>
  getOrganizationsForCurrentUser() async {
    final userResult = await _userRepository.getUser();
    if (userResult.isFailure) {
      return Result.failure(userResult.error);
    }

    try {
      final profileId = userResult.value.id;
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
      final orgs = results.map((row) {
        final orgData = row['organization'] as Map<String, dynamic>;
        return OrganizationWithRole(
          organization: OrganizationDto.fromJson(orgData),
          role: _parseMemberRole(row['role'] as String?),
        );
      }).toList();

      return Result.success(orgs);
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.getOrganizationsForCurrentUser',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Organization>> createOrganization(
    String name,
    String ownerId,
  ) async {
    try {
      final slug = _normalizeSlug(name);
      final response =
          await _supabase
              .from('organizations')
              .insert({'name': name, 'slug': slug, 'owner_id': ownerId})
              .select()
              .single();

      return Result.success(OrganizationDto.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == '23505') return Result.failure(const OrgAlreadyExists());
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.createOrganization',
        error: e,
        stackTrace: StackTrace.current,
      );
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.createOrganization',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> addMember(
    String organizationId,
    String profileId,
    OrganizationRole role,
  ) async {
    try {
      final existing =
          await _supabase
              .from('organization_members')
              .select()
              .eq('organization_id', organizationId)
              .eq('profile_id', profileId)
              .maybeSingle();

      if (existing != null) {
        return const Result.voidResult();
      }

      await _supabase.from('organization_members').insert({
        'organization_id': organizationId,
        'profile_id': profileId,
        'role': _roleToString(role),
      });

      return const Result.voidResult();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return Result.failure(const MemberAlreadyExists());
      }
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.addMember',
        error: e,
        stackTrace: StackTrace.current,
      );
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.addMember',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Organization?>> getOrganizationById(
    String organizationId,
  ) async {
    try {
      final res =
          await _supabase
              .from('organizations')
              .select()
              .eq('id', organizationId)
              .maybeSingle();
      return Result.success(res != null ? OrganizationDto.fromJson(res) : null);
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.getOrganizationById',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> updateOrganizationName(
    String organizationId,
    String name,
  ) async {
    try {
      await _supabase
          .from('organizations')
          .update({'name': name})
          .eq('id', organizationId);
      return const Result.voidResult();
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.updateOrganizationName',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<MemberWithProfile>>> getOrganizationMembers(
    String organizationId,
  ) async {
    try {
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
      final members = results.map((row) {
        final profile = row['profile'] as Map<String, dynamic>;
        return MemberWithProfile(
          profileId: profile['id'] as String,
          firstName: profile['first_name'] as String? ?? '',
          lastName: profile['last_name'] as String? ?? '',
          email: profile['email'] as String? ?? '',
          role: _parseMemberRole(row['role'] as String?),
        );
      }).toList();

      return Result.success(members);
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.getOrganizationMembers',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> updateMemberRole(
    String organizationId,
    String profileId,
    OrganizationRole newRole,
  ) async {
    try {
      await _supabase
          .from('organization_members')
          .update({'role': _roleToString(newRole)})
          .eq('organization_id', organizationId)
          .eq('profile_id', profileId);
      return const Result.voidResult();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        return Result.failure(const UnauthorizedOrgAccess());
      }
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.updateMemberRole',
        error: e,
        stackTrace: StackTrace.current,
      );
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseOrganizationRepository.updateMemberRole',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
