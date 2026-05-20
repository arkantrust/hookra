import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';

class OrgInviteDto {
  static OrgInvite fromJson(Map<String, dynamic> json) {
    return OrgInvite(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      email: json['email'] as String,
      role: _parseRole(json['role'] as String?),
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
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

  static String roleToString(OrganizationRole role) {
    switch (role) {
      case OrganizationRole.owner:
        return 'owner';
      case OrganizationRole.admin:
        return 'admin';
      case OrganizationRole.member:
        return 'member';
    }
  }
}
