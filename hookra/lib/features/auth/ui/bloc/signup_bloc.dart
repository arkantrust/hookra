import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/features/auth/domain/usecases/signup_usecase.dart';

// Events
abstract class SignupEvent {}

class SignupSubmitEvent extends SignupEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  SignupSubmitEvent({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });
}

// States
abstract class SignupState {}

class SignupInitialState extends SignupState {}

class SignupLoadingState extends SignupState {}

class SignupSuccessState extends SignupState {}

class SignupFailState extends SignupState {
  final String message;
  SignupFailState(this.message);
}

// BLoC
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupUsecase signupUsecase = SignupUsecase();

  SignupBloc() : super(SignupInitialState()) {
    on<SignupSubmitEvent>((event, emit) async {
      emit(SignupLoadingState());
      try {
        await signupUsecase.execute(
          event.firstName,
          event.lastName,
          event.email,
          event.password,
        );
        emit(SignupSuccessState());
      } catch (e) {
        emit(SignupFailState(_mapError(e.toString())));
      }
    });
  }

  String _mapError(String error) {
    if (error.contains('already')) return 'Este correo ya está registrado';
    if (error.contains('weak')) return 'La contraseña es muy débil';
    if (error.contains('network') || error.contains('socket')) {
      return 'No estás conectado a internet';
    }
    return 'Error: $error';
  }
}
