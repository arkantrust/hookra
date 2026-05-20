import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/data/models/org_invite_dto.dart';
import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/organizations/domain/failures/org_invite_failure.dart';
import 'package:hookra/src/utils/result.dart';

class SupabaseInviteRepository extends InviteRepository {
  SupabaseInviteRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<Result<OrgInvite>> createInvite(
    String organizationId,
    String email,
    OrganizationRole role,
  ) async {
    try {
      final profileRow = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (profileRow == null) return Result.failure(const UserNotFound());
      final profileId = profileRow['id'] as String;

      final memberRow = await _supabase
          .from('organization_members')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('profile_id', profileId)
          .maybeSingle();
      if (memberRow != null) return Result.failure(const AlreadyMember());

      final currentUser = _supabase.auth.currentUser;
      final response = await _supabase
          .from('org_invites')
          .insert({
            'organization_id': organizationId,
            'email': email,
            'role': OrgInviteDto.roleToString(role),
            'created_by': currentUser?.id,
          })
          .select()
          .single();

      return Result.success(OrgInviteDto.fromJson(response));
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseInviteRepository.createInvite',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
