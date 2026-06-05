import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:test/test.dart';

void main() {
  final teamJson = {
    'id': 'team-uuid-1',
    'organization_id': 'org-uuid-1',
    'name': 'Acme Corp',
    'description': null,
    'logo_url': null,
    'created_by': 'profile-uuid-1',
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  group('Team.fromJson', () {
    test('parses all required fields', () {
      final team = Team.fromJson(teamJson);

      expect(team.id, 'team-uuid-1');
      expect(team.organizationId, 'org-uuid-1');
      expect(team.name, 'Acme Corp');
      expect(team.createdBy, 'profile-uuid-1');
      expect(team.description, isNull);
      expect(team.logoUrl, isNull);
    });

    test('parses createdAt as DateTime', () {
      final team = Team.fromJson(teamJson);
      expect(team.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
    });

    test('parses optional description', () {
      final json = {...teamJson, 'description': 'A top client'};
      final team = Team.fromJson(json);
      expect(team.description, 'A top client');
    });
  });

  group('Team equality', () {
    test('two teams with same fields are equal', () {
      final t1 = Team.fromJson(teamJson);
      final t2 = Team.fromJson(teamJson);
      expect(t1, equals(t2));
    });

    test('teams with different names are not equal', () {
      final t1 = Team.fromJson(teamJson);
      final t2 = Team.fromJson({...teamJson, 'name': 'Other Corp'});
      expect(t1, isNot(equals(t2)));
    });
  });
}
