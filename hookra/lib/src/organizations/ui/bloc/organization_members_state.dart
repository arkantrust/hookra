part of 'organization_members_bloc.dart';

enum OrganizationMembersStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class OrganizationMembersState extends Equatable {
  final OrganizationMembersStatus status;
  final List<OrganizationMember> members;
  final Organization? organization;
  final OrgRole? currentUserRole;
  final String? updatingMemberId;
  final String? error;

  const OrganizationMembersState({
    this.status = OrganizationMembersStatus.initial,
    this.members = const [],
    this.organization,
    this.currentUserRole,
    this.updatingMemberId,
    this.error,
  });

  OrganizationMembersState copyWith({
    OrganizationMembersStatus? status,
    List<OrganizationMember>? members,
    Organization? organization,
    OrgRole? currentUserRole,
    String? updatingMemberId,
    String? error,
  }) {
    return OrganizationMembersState(
      status: status ?? this.status,
      members: members ?? this.members,
      organization: organization ?? this.organization,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      updatingMemberId: updatingMemberId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        members,
        organization,
        currentUserRole,
        updatingMemberId,
        error,
      ];
}