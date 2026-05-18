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

  @override
  List<Object?> get props => [organizationId, profileId, role];
}
