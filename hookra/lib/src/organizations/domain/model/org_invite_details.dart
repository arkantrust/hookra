import 'package:equatable/equatable.dart';
import 'package:hookra/src/organizations/domain/model/org_invite.dart';

class OrgInviteDetails extends Equatable {
  final OrgInvite invite;
  final String organizationName;
  final String ownerFullName;

  const OrgInviteDetails({
    required this.invite,
    required this.organizationName,
    required this.ownerFullName,
  });

  @override
  List<Object?> get props => [invite, organizationName, ownerFullName];
}
