import 'package:test/test.dart';
import 'package:hookra/src/ai_chat/domain/entities/agent_message.dart';

void main() {
  group('AgentMessage', () {
    test('toJson maps user role', () {
      const msg = AgentMessage(role: AgentMessageRole.user, text: 'Hello');
      expect(msg.toJson(), {'role': 'user', 'text': 'Hello'});
    });

    test('toJson maps agent role', () {
      const msg = AgentMessage(role: AgentMessageRole.agent, text: 'Done');
      expect(msg.toJson(), {'role': 'agent', 'text': 'Done'});
    });

    test('equality holds for same values', () {
      const a = AgentMessage(role: AgentMessageRole.user, text: 'X');
      const b = AgentMessage(role: AgentMessageRole.user, text: 'X');
      expect(a, equals(b));
    });

    test('inequality for different text', () {
      const a = AgentMessage(role: AgentMessageRole.user, text: 'A');
      const b = AgentMessage(role: AgentMessageRole.user, text: 'B');
      expect(a, isNot(equals(b)));
    });
  });
}
