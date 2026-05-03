import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:hookra/src/authentication/repository/authentication_repository.dart';
import 'package:hookra/src/profile/user_repository/user_repository.dart';
import 'package:hookra/src/models/models.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository _authenticationRepository;
  final UserRepository _userRepository;

  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
    required UserRepository userRepository,
  }) : _authenticationRepository = authenticationRepository,
       _userRepository = userRepository,
       super(AuthenticationState.unknown()) {
    on<AuthenticationSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthenticationSignOutPressed>(_onSignOutPressed);
  }

  Future<void> _onSubscriptionRequested(
    AuthenticationSubscriptionRequested event,
    Emitter<AuthenticationState> emit,
  ) {
    return emit.onEach(
      _authenticationRepository.status,
      onData:
          (status) async => switch (status) {
            AuthenticationStatus.unauthenticated => emit(
              const AuthenticationState.unauthenticated(),
            ),
            AuthenticationStatus.authenticated => await _emitUserIfExists(emit),
            AuthenticationStatus.unknown => emit(const AuthenticationState.unknown()),
          },
      onError: addError,
    );
  }

  void _onSignOutPressed(AuthenticationSignOutPressed event, Emitter<AuthenticationState> emit) {
    _authenticationRepository.signOut();
    _userRepository.dispose(); // Remove user from cache
  }

  Future<void> _emitUserIfExists(Emitter<AuthenticationState> emit) async {
    final res = await _userRepository.getUser();

    if (res.isFailure) {
      emit(const AuthenticationState.unauthenticated());
      return;
    }
    final user = res.value;
    emit(AuthenticationState.authenticated(user));
  }
}
