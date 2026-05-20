import 'package:equatable/equatable.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';

class OrgInvite extends Equatable {
  final String id;
  final String organizationId;
  final String email;
  final OrganizationRole role;
  final String token;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  const OrgInvite({
    required this.id,
    required this.organizationId,
    required this.email,
    required this.role,
    required this.token,
    required this.expiresAt,
    this.acceptedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAccepted => acceptedAt != null;

  @override
  List<Object?> get props => [id, organizationId, email, role, token, expiresAt, acceptedAt];
}
