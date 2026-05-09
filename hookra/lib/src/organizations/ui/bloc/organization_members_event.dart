part of 'organization_members_bloc.dart';

abstract class OrganizationMembersEvent extends Equatable {
  const OrganizationMembersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrganizationMembers extends OrganizationMembersEvent {
  final String organizationId;

  const LoadOrganizationMembers(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class UpdateMemberRole extends OrganizationMembersEvent {
  final String memberId;
  final OrgRole newRole;

  const UpdateMemberRole({
    required this.memberId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [memberId, newRole];
}