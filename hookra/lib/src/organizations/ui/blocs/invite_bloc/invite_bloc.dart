import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/use_cases/create_invite_use_case.dart';

part 'invite_event.dart';
part 'invite_state.dart';

const _deepLinkScheme = 'app.ddulce.hookra://invite?token=';

class InviteBloc extends Bloc<InviteEvent, InviteState> {
  final CreateInviteUseCase _createInvite;

  InviteBloc({required CreateInviteUseCase createInvite})
      : _createInvite = createInvite,
        super(const InviteState.initial()) {
    on<InviteSubmitted>(_onInviteSubmitted);
  }

  Future<void> _onInviteSubmitted(
    InviteSubmitted event,
    Emitter<InviteState> emit,
  ) async {
    emit(const InviteState.loading());

    final result = await _createInvite(
      organizationId: event.organizationId,
      email: event.email,
      role: event.role,
    );

    result.fold(
      (invite) => emit(InviteState.success('$_deepLinkScheme${invite!.token}')),
      (error) => emit(InviteState.failure(error.toString())),
    );
  }
}
