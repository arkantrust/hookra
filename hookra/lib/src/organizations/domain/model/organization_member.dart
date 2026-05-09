import 'package:equatable/equatable.dart';

enum OrganizationRole { owner, admin, member }

class OrganizationMember extends Equatable {
  final String organizationId;
  final String profileId;
  final OrganizationRole role;

  const OrganizationMember({
    required this.organizationId,
    required this.profileId,
    required this.role,
  });

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      organizationId: json['organization_id'] as String,
      profileId: json['profile_id'] as String,
      role: _parseRole(json['role'] as String?),
    );
  }

  static OrganizationRole _parseRole(String? role) {
    switch (role) {
      case 'owner':
        return OrganizationRole.owner;
      case 'admin':
        return OrganizationRole.admin;
      default:
        return OrganizationRole.member;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': _roleToString(role),
    };
  }

  static String _roleToString(OrganizationRole role) {
    switch (role) {
      case OrganizationRole.owner:
        return 'owner';
      case OrganizationRole.admin:
        return 'admin';
      case OrganizationRole.member:
        return 'member';
    }
  }

  @override
  List<Object?> get props => [organizationId, profileId, role];
}
