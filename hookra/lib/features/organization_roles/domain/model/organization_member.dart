enum OrganizationRole { member, admin, owner }

extension OrganizationRoleMapper on OrganizationRole {
  String get databaseValue {
    return switch (this) {
      OrganizationRole.member => 'member',
      OrganizationRole.admin => 'admin',
      OrganizationRole.owner => 'owner',
    };
  }

  String get label {
    return switch (this) {
      OrganizationRole.member => 'miembro',
      OrganizationRole.admin => 'admin',
      OrganizationRole.owner => 'owner',
    };
  }

  static OrganizationRole fromDatabase(String rawRole) {
    switch (rawRole.toLowerCase()) {
      case 'admin':
        return OrganizationRole.admin;
      case 'owner':
        return OrganizationRole.owner;
      case 'member':
      case 'miembro':
      default:
        return OrganizationRole.member;
    }
  }
}

class OrganizationMember {
  final String organizationId;
  final String profileId;
  final OrganizationRole role;
  final String firstName;
  final String lastName;
  final String email;

  const OrganizationMember({
    required this.organizationId,
    required this.profileId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) {
      return name;
    }
    if (email.isNotEmpty) {
      return email;
    }
    return profileId.substring(0, 8);
  }

  OrganizationMember copyWith({
    String? organizationId,
    String? profileId,
    OrganizationRole? role,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return OrganizationMember(
      organizationId: organizationId ?? this.organizationId,
      profileId: profileId ?? this.profileId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}
