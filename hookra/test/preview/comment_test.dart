import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:test/test.dart';

void main() {
  group('Comment', () {
    final baseJson = {
      'id': 'abc-123',
      'content_id': 'content-456',
      'user_id': 'user-789',
      'profiles': {'first_name': 'Alice', 'last_name': 'Smith'},
      'body': 'Great hook!',
      'created_at': '2026-06-08T10:00:00.000Z',
      'updated_at': '2026-06-08T10:05:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final comment = Comment.fromJson(baseJson);

      expect(comment.id, 'abc-123');
      expect(comment.contentId, 'content-456');
      expect(comment.userId, 'user-789');
      expect(comment.authorName, 'Alice Smith');
      expect(comment.body, 'Great hook!');
      expect(comment.createdAt, DateTime.parse('2026-06-08T10:00:00.000Z'));
      expect(comment.updatedAt, DateTime.parse('2026-06-08T10:05:00.000Z'));
    });

    test('fromJson uses "Unknown" when profiles is null', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['profiles'] = null;
      final comment = Comment.fromJson(json);
      expect(comment.authorName, 'Unknown');
    });

    test('two Comments with same fields are equal', () {
      final a = Comment.fromJson(baseJson);
      final b = Comment.fromJson(baseJson);
      expect(a, equals(b));
    });

    test('fromJson uses "Unknown" when both name fields are empty strings', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['profiles'] = {'first_name': '', 'last_name': ''};
      final comment = Comment.fromJson(json);
      expect(comment.authorName, 'Unknown');
    });
  });
}
