import 'package:equatable/equatable.dart';

enum OrganizationRole { owner, member }

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
      role: json['role'] == 'owner' ? OrganizationRole.owner : OrganizationRole.member,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': role == OrganizationRole.owner ? 'owner' : 'member',
    };
  }

  @override
  List<Object?> get props => [organizationId, profileId, role];
}