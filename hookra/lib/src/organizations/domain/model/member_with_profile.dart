import 'package:hookra/src/organizations/domain/model/organization_member.dart';

class MemberWithProfile {
  final String profileId;
  final String firstName;
  final String lastName;
  final String email;
  final OrganizationRole role;

  MemberWithProfile({
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });
}
