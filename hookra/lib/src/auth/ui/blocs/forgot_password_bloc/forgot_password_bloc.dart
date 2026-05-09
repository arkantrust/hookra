import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import 'package:hookra/src/auth/domain/use_cases/send_password_reset_use_case.dart';
import 'package:hookra/src/auth/domain/value_objects/email.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final SendPasswordResetUseCase _sendPasswordReset;

  ForgotPasswordBloc({required SendPasswordResetUseCase sendPasswordReset})
      : _sendPasswordReset = sendPasswordReset,
        super(ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>(_onEmailChanged);
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  void _onEmailChanged(
    ForgotPasswordEmailChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    final email = Email.dirty(event.email);
    emit(state.copyWith(email: email));
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    // We intentionally ignore failures here — always show success to prevent
    // user enumeration (attacker cannot learn whether an email is registered).
    await _sendPasswordReset(email: state.email.value);

    emit(state.copyWith(status: FormzSubmissionStatus.success));
  }
}
