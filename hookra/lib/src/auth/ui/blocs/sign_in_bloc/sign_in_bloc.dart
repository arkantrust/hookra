import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import 'package:hookra/src/auth/domain/failures/auth_failure.dart';
import 'package:hookra/src/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:hookra/src/auth/domain/value_objects/email.dart';
import 'package:hookra/src/auth/domain/value_objects/password.dart';
import 'package:hookra/src/utils/network.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInUseCase _signIn;

  SignInBloc({required SignInUseCase signIn}) : _signIn = signIn, super(SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInSubmitted>(_onSubmitted);
  }

  void _onEmailChanged(SignInEmailChanged event, Emitter<SignInState> emit) {
    final email = Email.dirty(event.email);
    emit(state.copyWith(email: email));
  }

  void _onPasswordChanged(SignInPasswordChanged event, Emitter<SignInState> emit) {
    final password = Password.dirty(event.password);
    emit(state.copyWith(password: password));
  }

  Future<void> _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress, error: ''));

    final res = await _signIn(email: state.email.value, password: state.password.value);

    if (res.isFailure) {
      final err = res.errorOrNull;
      String msg = switch (err) {
        WrongPassword _ => 'Contraseña incorrecta',
        EmailNotFound _ => 'No estás registrado',
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
