part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

final class AuthSubscriptionRequested extends AuthEvent {}

final class AuthSignOutPressed extends AuthEvent {}

final class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}
