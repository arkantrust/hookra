part of 'invite_bloc.dart';

enum InviteStatus { initial, loading, success, failure }

final class InviteState extends Equatable {
  final InviteStatus status;
  final String? inviteLink;
  final String? errorMessage;

  const InviteState._({
    this.status = InviteStatus.initial,
    this.inviteLink,
    this.errorMessage,
  });

  const InviteState.initial() : this._();

  const InviteState.loading() : this._(status: InviteStatus.loading);

  const InviteState.success(String link)
      : this._(status: InviteStatus.success, inviteLink: link);

  const InviteState.failure(String message)
      : this._(status: InviteStatus.failure, errorMessage: message);

  @override
  List<Object?> get props => [status, inviteLink, errorMessage];
}
