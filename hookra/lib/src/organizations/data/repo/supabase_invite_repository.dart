import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/data/models/org_invite_dto.dart';
import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/org_invite_details.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/organizations/domain/failures/org_invite_failure.dart';
import 'package:hookra/src/utils/result.dart';

class SupabaseInviteRepository extends InviteRepository {
  SupabaseInviteRepository({required this._supabase});

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
  Future<Result<OrgInviteDetails>> getInviteByToken(String token) async {
    try {
      final row = await _supabase
          .from('org_invites')
          .select(
            '*, organizations(name), profiles!created_by(first_name, last_name)',
          )
          .eq('token', token)
          .maybeSingle();

      if (row == null) return Result.failure(const InviteNotFound());

      final invite = OrgInviteDto.fromJson(row);
      final orgName = (row['organizations'] as Map<String, dynamic>)['name'] as String;
      final creator = row['profiles'] as Map<String, dynamic>;
      final ownerFullName =
          '${creator['first_name']} ${creator['last_name']}'.trim();

      return Result.success(
        OrgInviteDetails(
          invite: invite,
          organizationName: orgName,
          ownerFullName: ownerFullName,
        ),
      );
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseInviteRepository.getInviteByToken',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> acceptInvite(String token) async {
    try {
      await _supabase.rpc('accept_org_invite', params: {'p_token': token});
      return Result.voidResult();
    } on PostgrestException catch (e, st) {
      if (e.message.contains('invite_not_found')) {
        return Result.failure(const InviteNotFound());
      }
      if (e.message.contains('invite_expired')) {
        return Result.failure(const InviteExpired());
      }
      return Result.unknown(
        name: 'SupabaseInviteRepository.acceptInvite',
        error: e,
        stackTrace: st,
      );
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseInviteRepository.acceptInvite',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
