part of 'organization_members_bloc.dart';

enum OrganizationMembersStatus { initial, loading, loaded, error }

class OrganizationMembersState extends Equatable {
  final OrganizationMembersStatus status;
  final Organization? organization;
  final List<MemberWithProfile> members;
  final String? errorMessage;

  const OrganizationMembersState({
    this.status = OrganizationMembersStatus.initial,
    this.organization,
    this.members = const [],
    this.errorMessage,
  });

  OrganizationMembersState copyWith({
    OrganizationMembersStatus? status,
    Organization? organization,
    List<MemberWithProfile>? members,
    String? errorMessage,
  }) {
    return OrganizationMembersState(
      status: status ?? this.status,
      organization: organization ?? this.organization,
      members: members ?? this.members,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, organization, members, errorMessage];
}
