import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/organizations/data/models/org_invite_dto.dart';
import 'package:hookra/src/organizations/domain/failures/org_invite_failure.dart';
import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

class SupabaseInviteRepository extends InviteRepository {
  SupabaseInviteRepository({
    required SupabaseClient supabase,
    required OrganizationRepository organizationRepository,
  })  : _supabase = supabase,
        _orgRepo = organizationRepository;

  final SupabaseClient _supabase;
  final OrganizationRepository _orgRepo;

  @override
  Future<Result<OrgInvite>> createInvite(
    String organizationId,
    String email,
    OrganizationRole role,
  ) async {
    try {
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
  Future<Result<OrgInvite>> getInviteByToken(String token) async {
    try {
      final response = await _supabase
          .from('org_invites')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (response == null) return Result.failure(const InviteNotFound());

      return Result.success(OrgInviteDto.fromJson(response));
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseInviteRepository.getInviteByToken',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> acceptInvite(String token, String profileId) async {
    final inviteResult = await getInviteByToken(token);
    if (inviteResult.isFailure) return Result.failure(inviteResult.error);

    final invite = inviteResult.value;

    if (invite.isExpired) return Result.failure(const InviteExpired());
    if (invite.isAccepted) return Result.failure(const InviteAlreadyAccepted());

    // Validate email matches the authenticated user's profile
    try {
      final profile = await _supabase
          .from('profiles')
          .select('email')
          .eq('id', profileId)
          .single();

      final profileEmail = profile['email'] as String;
      if (profileEmail.toLowerCase() != invite.email.toLowerCase()) {
        return Result.failure(const InviteEmailMismatch());
      }
    } catch (e, st) {
      return Result.unknown(
        name: 'SupabaseInviteRepository.acceptInvite.validateEmail',
        error: e,
        stackTrace: st,
      );
    }

    final addResult = await _orgRepo.addMember(
      invite.organizationId,
      profileId,
      invite.role,
    );
    if (addResult.isFailure) return addResult;

    try {
      await _supabase
          .from('org_invites')
          .update({'accepted_at': DateTime.now().toIso8601String()})
          .eq('token', token);

      return const Result.voidResult();
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
