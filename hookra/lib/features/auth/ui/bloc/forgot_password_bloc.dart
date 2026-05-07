import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/features/auth/domain/repo/auth_repo.dart';
import 'package:hookra/features/auth/data/repo/auth_repo_impl.dart';

// Events
abstract class ForgotPasswordEvent {}

class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordSubmitted(this.email);
}

// States
abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordSuccess extends ForgotPasswordState {}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String message;
  ForgotPasswordFailure(this.message);
}

// BLoC
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepo repo;

  ForgotPasswordBloc({AuthRepo? repo}) : repo = repo ?? AuthRepoImpl(), super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>((event, emit) async {
      emit(ForgotPasswordLoading());
      try {
        // Use a deep link that points back to the app's reset password route.
        const redirectTo = 'hookra://reset-password';
        await this.repo.sendPasswordReset(event.email, redirectTo: redirectTo);
        // Always show success message (prevent enumeration)
        emit(ForgotPasswordSuccess());
      } catch (e) {
        emit(ForgotPasswordFailure('Algo salió mal. Intenta de nuevo.'));
      }
    });
  }
}
