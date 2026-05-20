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

  @override
  List<Object?> get props => [id, name, slug, ownerId, createdAt];
}
