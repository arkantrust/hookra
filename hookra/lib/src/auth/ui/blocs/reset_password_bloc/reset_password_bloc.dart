import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import 'package:hookra/src/auth/domain/failures/auth_failure.dart';
import 'package:hookra/src/auth/domain/use_cases/reset_password_use_case.dart';
import 'package:hookra/src/auth/domain/use_cases/reset_password_with_token_use_case.dart';
import 'package:hookra/src/auth/domain/value_objects/password.dart';
import 'package:hookra/src/config/auth_token_holder.dart';
import 'package:hookra/src/utils/network.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ResetPasswordUseCase _resetPassword;
  final ResetPasswordWithTokenUseCase _resetPasswordWithToken;

  ResetPasswordBloc({
    required ResetPasswordUseCase resetPassword,
    required ResetPasswordWithTokenUseCase resetPasswordWithToken,
  })  : _resetPassword = resetPassword,
        _resetPasswordWithToken = resetPasswordWithToken,
        super(ResetPasswordState()) {
    on<ResetPasswordNewChanged>(_onNewChanged);
    on<ResetPasswordConfirmChanged>(_onConfirmChanged);
    on<ResetPasswordSubmitted>(_onSubmitted);
  }

  void _onNewChanged(
    ResetPasswordNewChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    final newPassword = Password.dirty(event.password);
    emit(state.copyWith(newPassword: newPassword));
  }

  void _onConfirmChanged(
    ResetPasswordConfirmChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    final confirm = Password.dirty(event.password);
    emit(state.copyWith(confirm: confirm));
  }

  Future<void> _onSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress, error: ''));

    // Consume the in-memory access token if it was stored by the deep link handler.
    final accessToken = AuthTokenHolder.instance.consumeAccessToken();

    final res = accessToken != null
        ? await _resetPasswordWithToken(
            accessToken: accessToken,
            newPassword: state.newPassword.value,
          )
        : await _resetPassword(state.newPassword.value);

    if (res.isFailure) {
      final err = res.errorOrNull;
      final msg = switch (err) {
        InvalidOrExpiredToken _ => 'token_expired',
        NoInternetConnection _ => 'No estás conectado a internet',
        ServerUnreachable _ => 'No fue posible acceder al servidor',
        _ => 'Algo salió mal',
      };
      emit(state.copyWith(status: FormzSubmissionStatus.failure, error: msg));
      return;
    }

    emit(state.copyWith(status: FormzSubmissionStatus.success, error: ''));
  }
}
