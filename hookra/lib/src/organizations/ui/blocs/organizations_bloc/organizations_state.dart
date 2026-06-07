part of 'organizations_bloc.dart';

enum OrganizationsStatus { initial, loading, success, failure, creating, createFailure, createSuccess }

class OrganizationsState extends Equatable {
  final OrganizationsStatus status;
  final List<OrganizationWithRole> organizations;
  final String? errorMessage;

  const OrganizationsState({
    this.status = OrganizationsStatus.initial,
    this.organizations = const [],
    this.errorMessage,
  });

  OrganizationsState copyWith({
    OrganizationsStatus? status,
    List<OrganizationWithRole>? organizations,
    String? errorMessage,
  }) {
    return OrganizationsState(
      status: status ?? this.status,
      organizations: organizations ?? this.organizations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, organizations, errorMessage];
}
