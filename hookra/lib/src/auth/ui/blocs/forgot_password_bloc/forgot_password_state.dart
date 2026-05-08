part of 'forgot_password_bloc.dart';

final class ForgotPasswordState extends Equatable {
  final FormzSubmissionStatus status;
  final Email email;
  final bool isValid;

  const ForgotPasswordState({
    this.status = FormzSubmissionStatus.initial,
    this.email = const Email.pure(),
    this.isValid = false,
  });

  ForgotPasswordState copyWith({
    FormzSubmissionStatus? status,
    Email? email,
  }) {
    final e = email ?? this.email;
    return ForgotPasswordState(
      status: status ?? this.status,
      email: e,
      isValid: Formz.validate([e]),
    );
  }

  @override
  List<Object> get props => [status, email, isValid];
}
