import 'package:equatable/equatable.dart';

class Organization extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String ownerId;
  final DateTime? createdAt;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerId,
    this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'owner_id': ownerId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, slug, ownerId, createdAt];
}