part of 'accept_invite_bloc.dart';

sealed class AcceptInviteEvent extends Equatable {
  const AcceptInviteEvent();

  @override
  List<Object?> get props => [];
}

final class AcceptInviteLoadRequested extends AcceptInviteEvent {
  final String token;
  final String? currentUserEmail;

  const AcceptInviteLoadRequested({
    required this.token,
    required this.currentUserEmail,
  });

  @override
  List<Object?> get props => [token, currentUserEmail];
}

final class AcceptInviteAcceptPressed extends AcceptInviteEvent {
  const AcceptInviteAcceptPressed();
}
