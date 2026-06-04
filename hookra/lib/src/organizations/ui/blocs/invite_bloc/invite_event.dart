part of 'invite_bloc.dart';

sealed class InviteEvent extends Equatable {
  const InviteEvent();

  @override
  List<Object?> get props => [];
}

final class InviteSubmitted extends InviteEvent {
  final String organizationId;
  final String email;
  final OrganizationRole role;

  const InviteSubmitted({
    required this.organizationId,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [organizationId, email, role];
}
