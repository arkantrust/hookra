import 'package:equatable/equatable.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';

enum OrganizationRole { owner, member, admin }

class OrganizationMember extends Equatable {
  final String id;
  final String organizationId;
  final String profileId;
  final OrgRole role;
  final String? invitedBy;
  final DateTime joinedAt;
  final User? profile;

  const OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.profileId,
    required this.role,
    this.invitedBy,
    required this.joinedAt,
    this.profile,
  });

  OrganizationMember copyWith({
    String? id,
    String? organizationId,
    String? profileId,
    OrgRole? role,
    String? invitedBy,
    DateTime? joinedAt,
    User? profile,
  }) {
    return OrganizationMember(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      profileId: profileId ?? this.profileId,
      role: role ?? this.role,
      invitedBy: invitedBy ?? this.invitedBy,
      joinedAt: joinedAt ?? this.joinedAt,
      profile: profile ?? this.profile,
    );
  }

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      profileId: json['profile_id'] as String,
      role: OrgRole.fromString(json['role'] as String),
      invitedBy: json['invited_by'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      profile: json['profile'] != null
          ? User(
              id: json['profile']['id'] as String,
              firstName: json['profile']['first_name'] as String,
              lastName: json['profile']['last_name'] as String,
              email: json['profile']['email'] as String,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'profile_id': profileId,
        'role': role.value,
        'invited_by': invitedBy,
        'joined_at': joinedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, organizationId, profileId, role, invitedBy, joinedAt, profile];
}