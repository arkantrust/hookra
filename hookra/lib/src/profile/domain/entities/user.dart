import 'package:equatable/equatable.dart';

/// {@template user}
/// User model
///
/// [User.empty] represents an unauthenticated user.
/// {@endtemplate}
class User extends Equatable {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.selectedOrgId,
    this.selectedTeamId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String? selectedOrgId;
  final String? selectedTeamId;

  String get fullName => '$firstName $lastName';

  /// Empty user represents an unauthenticated user.
  static const empty = User(id: '', firstName: '', lastName: '', email: '');

  factory User.fromJson(Map<String, Object?> json) => User(
    id: json['id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    email: json['email'] as String,
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'avatar_url': avatarUrl ?? '',
  };

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    avatarUrl,
    selectedOrgId,
    selectedTeamId,
  ];
}
