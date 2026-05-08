part of 'reset_password_bloc.dart';

sealed class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object> get props => [];
}

final class ResetPasswordNewChanged extends ResetPasswordEvent {
  const ResetPasswordNewChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

final class ResetPasswordConfirmChanged extends ResetPasswordEvent {
  const ResetPasswordConfirmChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

final class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted();
}
