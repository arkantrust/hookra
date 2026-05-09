part of 'organization_members_bloc.dart';

abstract class OrganizationMembersEvent extends Equatable {
  const OrganizationMembersEvent();

  @override
  List<Object?> get props => [];
}

class LoadMembers extends OrganizationMembersEvent {
  final String organizationId;

  const LoadMembers(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class UpdateMemberRole extends OrganizationMembersEvent {
  final String organizationId;
  final String profileId;
  final OrganizationRole newRole;

  const UpdateMemberRole({
    required this.organizationId,
    required this.profileId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [organizationId, profileId, newRole];
}
