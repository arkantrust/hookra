import 'package:equatable/equatable.dart';
import 'organization.dart';
import 'organization_member.dart';

class OrganizationWithRole extends Equatable {
  final Organization organization;
  final OrganizationRole role;

  const OrganizationWithRole({
    required this.organization,
    required this.role,
  });

  @override
  List<Object?> get props => [organization, role];
}