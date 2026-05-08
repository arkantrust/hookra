part of 'reset_password_bloc.dart';

final class ResetPasswordState extends Equatable {
  final FormzSubmissionStatus status;
  final Password newPassword;
  final Password confirm;
  final bool isValid;
  final String error;

  const ResetPasswordState({
    this.status = FormzSubmissionStatus.initial,
    this.newPassword = const Password.pure(),
    this.confirm = const Password.pure(),
    this.isValid = false,
    this.error = '',
  });

  ResetPasswordState copyWith({
    FormzSubmissionStatus? status,
    Password? newPassword,
    Password? confirm,
    String? error,
  }) {
    final np = newPassword ?? this.newPassword;
    final c = confirm ?? this.confirm;
    // Both fields must be valid AND must match to allow submission.
    final bothValid = Formz.validate([np, c]) && np.value == c.value;
    return ResetPasswordState(
      status: status ?? this.status,
      newPassword: np,
      confirm: c,
      isValid: bothValid,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [status, newPassword, confirm, isValid, error];
}
