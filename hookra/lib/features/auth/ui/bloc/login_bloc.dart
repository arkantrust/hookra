import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/features/auth/domain/usecases/login_usecase.dart';

// Events
abstract class LoginEvent {}

class LoginSubmitEvent extends LoginEvent {
  final String email;
  final String password;
  LoginSubmitEvent({required this.email, required this.password});
}

// States
abstract class LoginState {}

class LoginInitialState extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginSuccessState extends LoginState {}

class LoginFailState extends LoginState {
  final String message;
  LoginFailState(this.message);
}

// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginUsecase loginUsecase = LoginUsecase();

  LoginBloc() : super(LoginInitialState()) {
    on<LoginSubmitEvent>((event, emit) async {
      emit(LoginLoadingState());
      try {
        await loginUsecase.execute(event.email, event.password);
        emit(LoginSuccessState());
      } catch (e) {
        emit(LoginFailState(_mapError(e.toString())));
      }
    });
  }

  String _mapError(String error) {
    if (error.contains('invalid_credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (error.contains('network') || error.contains('socket')) {
      return 'No estás conectado a internet';
    }
    return 'Algo salió mal, intenta de nuevo';
  }
}
