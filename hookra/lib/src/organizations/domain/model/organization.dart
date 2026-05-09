import 'package:equatable/equatable.dart';

class Organization extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo_url': logoUrl,
        'owner_id': ownerId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, name, slug, logoUrl, ownerId, createdAt, updatedAt];
}