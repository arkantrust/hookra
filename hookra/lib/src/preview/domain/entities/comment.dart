import 'package:equatable/equatable.dart';

/// A comment on a [Content] item, as stored in the `content_comments` table.
///
/// [authorName] is denormalized from a `profiles!user_id(first_name, last_name)`
/// Supabase join. If the join key is renamed at the query site, update this field
/// name accordingly.
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.contentId,
    required this.userId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.resolved,
    this.contentTitle,
  });

  final String id;
  final String contentId;
  final String userId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool resolved;

  /// Populated only when the comment is fetched via a team query that joins
  /// the `content` table (e.g. [CommentRepository.getUnresolvedCommentsForTeam]).
  final String? contentTitle;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final first = profile?['first_name'] as String? ?? '';
    final last = profile?['last_name'] as String? ?? '';
    final name = '$first $last'.trim();
    final content = json['content'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'] as String,
      contentId: json['content_id'] as String,
      userId: json['user_id'] as String,
      authorName: name.isEmpty ? 'Unknown' : name,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolved: json['resolved'] as bool? ?? false,
      contentTitle: content?['title'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        userId,
        authorName,
        body,
        createdAt,
        updatedAt,
        resolved,
        contentTitle,
      ];
}
