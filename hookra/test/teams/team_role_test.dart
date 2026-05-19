import 'package:hookra/src/teams/domain/entities/team_role.dart';
import 'package:test/test.dart';

void main() {
  group('teamRoleFromJson', () {
    test('parses manager', () {
      expect(teamRoleFromJson('manager'), TeamRole.manager);
    });

    test('parses editor', () {
      expect(teamRoleFromJson('editor'), TeamRole.editor);
    });

    test('defaults to editor for unknown value', () {
      expect(teamRoleFromJson('unknown'), TeamRole.editor);
    });

    test('defaults to editor for null', () {
      expect(teamRoleFromJson(null), TeamRole.editor);
    });
  });

  group('TeamRole.toJson', () {
    test('manager serializes to manager', () {
      expect(TeamRole.manager.toJson(), 'manager');
    });

    test('editor serializes to editor', () {
      expect(TeamRole.editor.toJson(), 'editor');
    });
  });
}
