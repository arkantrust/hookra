import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:hookra/src/auth/domain/repo/auth_repository.dart'
    show AuthStatus;
import 'package:hookra/src/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:hookra/src/auth/domain/use_cases/watch_auth_status_use_case.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/profile/domain/use_cases/get_user_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final WatchAuthStatusUseCase _watchStatus;
  final SignOutUseCase _signOut;
  final GetUserUseCase _getUser;

  AuthBloc({
    required WatchAuthStatusUseCase watchStatus,
    required SignOutUseCase signOut,
    required GetUserUseCase getUser,
  }) : _watchStatus = watchStatus,
       _signOut = signOut,
       _getUser = getUser,
       super(AuthState.unknown()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignOutPressed>(_onSignOutPressed);
    on<AuthProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) {
    return emit.onEach(
      _watchStatus(),
      onData:
          (status) async => switch (status) {
            AuthStatus.unauthenticated => emit(
              const AuthState.unauthenticated(),
            ),
            AuthStatus.authenticated => await _emitUserIfExists(emit),
            AuthStatus.unknown => emit(const AuthState.unknown()),
          },
      onError: addError,
    );
  }

  void _onSignOutPressed(AuthSignOutPressed event, Emitter<AuthState> emit) {
    _signOut();
    _getUser.dispose(); // Remove user from cache
  }

  void _onProfileUpdated(AuthProfileUpdated event, Emitter<AuthState> emit) {
    emit(AuthState.authenticated(event.user));
  }

  Future<void> _emitUserIfExists(Emitter<AuthState> emit) async {
    final res = await _getUser();

    if (res.isFailure) {
      emit(const AuthState.unauthenticated());
      return;
    }
    final user = res.value;
    emit(AuthState.authenticated(user));
  }
}
