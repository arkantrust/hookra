import 'package:equatable/equatable.dart';

enum ContentStatus {
  draft,
  approved,
  published,
}

/// A piece of generated content as stored in the `content` table.
class Content extends Equatable {
  const Content({
    required this.id,
    required this.title,
    required this.platform,
    required this.format,
    required this.status,
    required this.teamId,
    this.projectId,
    this.hook,
    this.script,
    this.caption,
    this.cta,
    this.hashtags = const [],
    required this.createdAt,
  });

  final String id;
  final String title;
  final String platform;
  final String format;
  final ContentStatus status;
  final String teamId;
  final String? projectId;
  final String? hook;
  final String? script;
  final String? caption;
  final String? cta;
  final List<String> hashtags;
  final DateTime createdAt;

  factory Content.fromJson(Map<String, dynamic> json) {
    // teamId viene de projects.team_id (join) o directo si ya está plano
    final teamId = (json['team_id'] as String?) ??
        (json['projects'] is Map ? json['projects']['team_id'] as String : null);
    final statusStr = json['status'] as String? ?? 'draft';
    return Content(
      id: json['id'] as String,
      title: json['title'] as String,
      platform: json['platform'] as String,
      format: json['format'] as String,
      status: ContentStatus.values.byName(statusStr),
      teamId: teamId ?? '',
      projectId: json['project_id'] as String?,
      hook: json['hook'] as String?,
      script: json['script'] as String?,
      caption: json['caption'] as String?,
      cta: json['cta'] as String?,
      hashtags:
          (json['hashtags'] as List?)?.map((e) => e as String).toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'platform': platform,
    'format': format,
    'status': status.name,
    'team_id': teamId,
    'project_id': projectId,
    'hook': hook,
    'script': script,
    'caption': caption,
    'cta': cta,
    'hashtags': hashtags,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    title,
    platform,
    format,
    status,
    teamId,
    projectId,
    hook,
    script,
    caption,
    cta,
    hashtags,
    createdAt,
  ];
}
