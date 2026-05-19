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
  void dispose() {}
}
