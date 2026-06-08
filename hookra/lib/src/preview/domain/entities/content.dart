import 'package:equatable/equatable.dart';

/// A piece of generated content as stored in the `content` table.
class Content extends Equatable {
  const Content({
    required this.id,
    required this.title,
    required this.platform,
    required this.format,
    required this.status,
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
  final String status;
  final String? hook;
  final String? script;
  final String? caption;
  final String? cta;
  final List<String> hashtags;
  final DateTime createdAt;

  factory Content.fromJson(Map<String, dynamic> json) => Content(
    id: json['id'] as String,
    title: json['title'] as String,
    platform: json['platform'] as String,
    format: json['format'] as String,
    status: json['status'] as String? ?? 'draft',
    hook: json['hook'] as String?,
    script: json['script'] as String?,
    caption: json['caption'] as String?,
    cta: json['cta'] as String?,
    hashtags:
        (json['hashtags'] as List?)?.map((e) => e as String).toList() ??
        const [],
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    title,
    platform,
    format,
    status,
    hook,
    script,
    caption,
    cta,
    hashtags,
    createdAt,
  ];
}
