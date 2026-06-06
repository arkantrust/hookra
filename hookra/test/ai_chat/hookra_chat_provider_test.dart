import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';
import 'package:hookra/src/ai_chat/domain/repos/agent_chat_repository.dart';
import 'package:hookra/src/ai_chat/domain/use_cases/send_message_use_case.dart';
import 'package:hookra/src/ai_chat/data/repos/hookra_chat_provider.dart';

final class _FakeRepository extends AgentChatRepository {
  _FakeRepository(this._chunks);
  final List<String> _chunks;

  @override
  Stream<String> sendMessage({
    required String contentId,
    required String prompt,
    required List<AgentMessage> history,
    required String platform,
    required String format,
    required String title,
  }) async* {
    for (final chunk in _chunks) {
      yield chunk;
    }
  }

  @override
  void dispose() {}
}

HookraChatProvider _makeProvider(List<String> chunks) => HookraChatProvider(
      sendMessage: SendMessageUseCase(_FakeRepository(chunks)),
      contentId: 'c-1',
      platform: 'instagram',
      format: 'reel',
      title: 'Test',
    );

void main() {
  group('HookraChatProvider', () {
    test('starts with empty history', () {
      expect(_makeProvider([]).history, isEmpty);
    });

    test('sendMessageStream adds user message immediately', () async {
      final provider = _makeProvider(['Hi']);
      await provider.sendMessageStream('Brief').toList();
      expect(provider.history.first.origin, MessageOrigin.user);
    });

    test('sendMessageStream yields all chunks', () async {
      final provider = _makeProvider(['Hello', ' World']);
      final chunks = await provider.sendMessageStream('Brief').toList();
      expect(chunks, ['Hello', ' World']);
    });

    test('sendMessageStream adds llm message to history', () async {
      final provider = _makeProvider(['Hello', ' World']);
      await provider.sendMessageStream('Brief').toList();
      expect(provider.history.length, 2);
      expect(provider.history.last.origin, MessageOrigin.llm);
    });

    test('agent message text equals concatenated chunks', () async {
      final provider = _makeProvider(['Hello', ' World']);
      await provider.sendMessageStream('Brief').toList();
      expect(provider.history.last.text, 'Hello World');
    });

    test('generateStream does not modify history', () async {
      final provider = _makeProvider(['Preview']);
      await provider.generateStream('Preview').toList();
      expect(provider.history, isEmpty);
    });
  });
}
