import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';
import 'package:hookra/src/ai_chat/domain/failures/ai_chat_failure.dart';
import 'package:hookra/src/ai_chat/domain/repos/agent_chat_repository.dart';

final class HookraAgentChatRepository extends AgentChatRepository {
  HookraAgentChatRepository({
    required SupabaseClient supabase,
    required String supabaseUrl,
  }) : _supabase = supabase,
       _supabaseUrl = supabaseUrl;

  final SupabaseClient _supabase;
  final String _supabaseUrl;

  @override
  Stream<String> sendMessage({
    required String orgId,
    required String teamId,
    required String prompt,
    required List<AgentMessage> history,
  }) async* {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      yield* Stream.error(const AiChatAuthFailure());
      return;
    }

    final url = Uri.parse('$_supabaseUrl/functions/v1/content-agent');
    final request = http.Request('POST', url)
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'org_id': orgId,
        'team_id': teamId,
        'prompt': prompt,
        'history': history.map((m) => m.toJson()).toList(),
      });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode == 401) {
        yield* Stream.error(const AiChatAuthFailure());
        return;
      }
      if (response.statusCode == 403) {
        yield* Stream.error(const AiChatAuthFailure());
        return;
      }
      if (response.statusCode == 404) {
        yield* Stream.error(const AiChatContentNotFoundFailure());
        return;
      }
      if (response.statusCode != 200) {
        yield* Stream.error(
          AiChatUnknownFailure('HTTP ${response.statusCode}'),
        );
        return;
      }

      yield* response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('data: '))
          .map((line) => line.substring(6))
          .where((data) => data.isNotEmpty && data != '[DONE]');
    } on Exception {
      yield* Stream.error(const AiChatNetworkFailure());
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {}
}
