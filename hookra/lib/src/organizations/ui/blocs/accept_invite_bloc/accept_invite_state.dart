part of 'accept_invite_bloc.dart';

sealed class AcceptInviteState extends Equatable {
  const AcceptInviteState();

  @override
  List<Object?> get props => [];
}

final class AcceptInviteInitial extends AcceptInviteState {
  const AcceptInviteInitial();
}

final class AcceptInviteLoading extends AcceptInviteState {
  const AcceptInviteLoading();
}

final class AcceptInviteLoaded extends AcceptInviteState {
  final OrgInviteDetails details;
  final bool canAccept;
  final String token;

  const AcceptInviteLoaded({
    required this.details,
    required this.canAccept,
    required this.token,
  });

  @override
  List<Object?> get props => [details, canAccept, token];
}

final class AcceptInviteExpired extends AcceptInviteState {
  final OrgInviteDetails details;

  const AcceptInviteExpired(this.details);

  @override
  List<Object?> get props => [details];
}

final class AcceptInviteNotForUser extends AcceptInviteState {
  final OrgInviteDetails details;

  const AcceptInviteNotForUser(this.details);

  @override
  List<Object?> get props => [details];
}

final class AcceptInviteAccepting extends AcceptInviteState {
  const AcceptInviteAccepting();
}

final class AcceptInviteAccepted extends AcceptInviteState {
  const AcceptInviteAccepted();
}

final class AcceptInviteError extends AcceptInviteState {
  final String message;
  final String? token;

  const AcceptInviteError(this.message, {this.token});

  @override
  List<Object?> get props => [message, token];
}
