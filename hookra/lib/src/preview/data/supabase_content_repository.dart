import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/preview/domain/repos/content_repository.dart';
import 'package:hookra/src/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseContentRepository extends ContentRepository {
  SupabaseContentRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<Result<Content?>> getLatestContentForTeam(String teamId) async {
    try {
      final data = await _supabase
          .from('content')
          .select('*, projects!inner(team_id)')
          .eq('projects.team_id', teamId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return Result.success(null);
      return Result.success(Content.fromJson(data));
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseContentRepository.getLatestContentForTeam',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Result<void>> updateContentStatus({
    required String contentId,
    required ContentStatus status,
  }) async {
    try {
      await _supabase
          .from('content')
          .update({'status': status.name})
          .eq('id', contentId)
          .single();
      return Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'SupabaseContentRepository.updateContentStatus',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void dispose() {}
}
