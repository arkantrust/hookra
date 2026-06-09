import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/entities/team_member.dart';
import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseTeamRepository extends TeamRepository {
  SupabaseTeamRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<Result<List<Team>>> getTeamsForOrganization(
    String organizationId,
  ) async {
    try {
      final data = await _supabase
          .from('teams')
          .select()
          .eq('organization_id', organizationId)
          .isFilter('deleted_at', null)
          .order('created_at');
      final teams = (data as List)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(teams);
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.getTeamsForOrganization',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<Team>> createTeam({
    required String organizationId,
    required String name,
    required String creatorProfileId,
  }) async {
    try {
      final teamData = await _supabase
          .from('teams')
          .insert({
            'organization_id': organizationId,
            'name': name,
            'created_by': creatorProfileId,
          })
          .select()
          .single();
      final team = Team.fromJson(teamData);

      await _supabase.from('team_members').insert({
        'team_id': team.id,
        'profile_id': creatorProfileId,
        'role': 'manager',
        'invited_by': creatorProfileId,
      });

      return Result.success(team);
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.createTeam',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<List<String>>> getTeamIdsForUser({
    required String profileId,
    required String organizationId,
  }) async {
    try {
      final data = await _supabase
          .from('team_members')
          .select('team_id, teams!inner(organization_id)')
          .eq('profile_id', profileId)
          .eq('teams.organization_id', organizationId);

      final teamIds = <String>{};
      for (final row in data as List) {
        final teamId = row['team_id'] as String?;
        if (teamId != null) teamIds.add(teamId);
      }

      return Result.success(teamIds.toList());
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.getTeamIdsForUser',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<void>> joinTeam({
    required String teamId,
    required String profileId,
    required String organizationId,
  }) async {
    try {
      final existing = await _supabase
          .from('team_members')
          .select('id, teams!inner(organization_id)')
          .eq('team_id', teamId)
          .eq('profile_id', profileId)
          .eq('teams.organization_id', organizationId)
          .maybeSingle();

      if (existing != null) {
        return Result.voidResult();
      }

      await _supabase.from('team_members').insert({
        'team_id': teamId,
        'profile_id': profileId,
        'role': 'editor',
        'invited_by': profileId,
      });

      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.joinTeam',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<void>> leaveTeam({
    required String teamId,
    required String profileId,
  }) async {
    try {
      await _supabase
          .from('team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('profile_id', profileId);

      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.leaveTeam',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<void>> deleteTeam(String teamId) async {
    try {
      await _supabase
          .from('teams')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', teamId);
      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.deleteTeam',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<List<TeamMember>>> getTeamMembers(String teamId) async {
    try {
      final data = await _supabase
          .from('team_members')
          .select(
            'profiles!team_members_profile_id_fkey(id, first_name, last_name, email)',
          )
          .eq('team_id', teamId);
      final members = (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>;
        return TeamMember.fromJson(profile);
      }).toList();
      return Result.success(members);
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.getTeamMembers',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void dispose() {}
}
