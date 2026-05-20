import 'package:equatable/equatable.dart';

class Team extends Equatable {
  const Team({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String createdBy;
  final DateTime createdAt;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    logoUrl: json['logo_url'] as String?,
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    organizationId,
    name,
    description,
    logoUrl,
    createdBy,
    createdAt,
  ];
}
