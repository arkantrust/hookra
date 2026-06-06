import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/failures/org_invite_failure.dart';
import 'package:hookra/src/organizations/domain/model/org_invite_details.dart';
import 'package:hookra/src/organizations/domain/use_cases/accept_invite_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/get_invite_by_token_use_case.dart';

part 'accept_invite_event.dart';
part 'accept_invite_state.dart';

class AcceptInviteBloc extends Bloc<AcceptInviteEvent, AcceptInviteState> {
  final GetInviteByTokenUseCase _getInviteByToken;
  final AcceptInviteUseCase _acceptInvite;

  AcceptInviteBloc({
    required this._getInviteByToken,
    required AcceptInviteUseCase acceptInvite,
  })  : _acceptInvite = acceptInvite,
        super(const AcceptInviteInitial()) {
    on<AcceptInviteLoadRequested>(_onLoadRequested);
    on<AcceptInviteAcceptPressed>(_onAcceptPressed);
  }

  Future<void> _onLoadRequested(
    AcceptInviteLoadRequested event,
    Emitter<AcceptInviteState> emit,
  ) async {
    emit(const AcceptInviteLoading());

    final result = await _getInviteByToken(event.token);

    result.fold(
      (details) {
        if (details!.invite.isExpired) {
          emit(AcceptInviteExpired(details));
          return;
        }
        if (event.currentUserEmail == null) {
          emit(AcceptInviteLoaded(
            details: details,
            canAccept: false,
            token: event.token,
          ));
          return;
        }
        if (event.currentUserEmail != details.invite.email) {
          emit(AcceptInviteNotForUser(details));
          return;
        }
        emit(AcceptInviteLoaded(
          details: details,
          canAccept: true,
          token: event.token,
        ));
      },
      (error) => emit(AcceptInviteError(
        switch (error) {
          InviteNotFound() => 'Esta invitación no existe o ya no es válida',
          _ => 'Ocurrió un error al cargar la invitación',
        },
        token: event.token,
      )),
    );
  }

  Future<void> _onAcceptPressed(
    AcceptInviteAcceptPressed event,
    Emitter<AcceptInviteState> emit,
  ) async {
    final current = state;
    if (current is! AcceptInviteLoaded || !current.canAccept) return;

    emit(const AcceptInviteAccepting());

    final result = await _acceptInvite(current.token);

    result.fold(
      (_) => emit(const AcceptInviteAccepted()),
      (error) => emit(AcceptInviteError(
        switch (error) {
          InviteExpired() => 'Esta invitación ha vencido',
          InviteNotFound() => 'Esta invitación no existe o ya no es válida',
          _ => 'Ocurrió un error al aceptar la invitación',
        },
        token: current.token,
      )),
    );
  }
}
