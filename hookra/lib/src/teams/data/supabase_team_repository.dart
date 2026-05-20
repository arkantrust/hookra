import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/repo/team_repository.dart';
import 'package:hookra/src/utils/result.dart';

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
  Future<Result<bool>> hasUserTeam(
    String profileId,
    String organizationId,
  ) async {
    try {
      final data = await _supabase
          .from('team_members')
          .select('team_id, teams!inner(organization_id)')
          .eq('profile_id', profileId)
          .eq('teams.organization_id', organizationId)
          .maybeSingle();

      return Result.success(data != null);
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.hasUserTeam',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<Team?>> getCurrentTeamForUser(
    String profileId,
    String organizationId,
  ) async {
    try {
      final data = await _supabase
          .from('team_members')
          .select('''
            team_id,
            teams:teams(id, organization_id, name, description, logo_url, created_by, created_at)
          ''')
          .eq('profile_id', profileId)
          .eq('teams.organization_id', organizationId)
          .maybeSingle();

      if (data == null || data['teams'] == null) {
        return Result.success(null);
      }

      final team = Team.fromJson(data['teams'] as Map<String, dynamic>);
      return Result.success(team);
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseTeamRepository.getCurrentTeamForUser',
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
          .eq('profile_id', profileId)
          .eq('teams.organization_id', organizationId)
          .maybeSingle();

      if (existing != null) {
        return Result.failure(Exception('User is already in a team'));
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
  void dispose() {}
}
