import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:hookra/src/auth/domain/value_objects/name.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/settings/domain/use_cases/update_profile_use_case.dart';
import 'package:hookra/src/utils/network.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final UpdateProfileUseCase _updateProfile;

  EditProfileBloc({required this._updateProfile})
    : super(const EditProfileState()) {
    on<EditProfileFirstChanged>(_onFirstChanged);
    on<EditProfileLastChanged>(_onLastChanged);
    on<EditProfileSubmitted>(_onSubmitted);
  }

  void _onFirstChanged(
    EditProfileFirstChanged event,
    Emitter<EditProfileState> emit,
  ) {
    emit(state.copyWith(first: Name.dirty(event.first)));
  }

  void _onLastChanged(
    EditProfileLastChanged event,
    Emitter<EditProfileState> emit,
  ) {
    emit(state.copyWith(last: Name.dirty(event.last)));
  }

  Future<void> _onSubmitted(
    EditProfileSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress, error: ''));

    final res = await _updateProfile(
      firstName: state.first.value,
      lastName: state.last.value,
    );

    if (res.isFailure) {
      final msg = switch (res.errorOrNull) {
        NoInternetConnection _ => 'Sin conexión a internet',
        ServerUnreachable _ => 'No fue posible acceder al servidor',
        _ => 'Algo salió mal',
      };
      emit(state.copyWith(status: FormzSubmissionStatus.failure, error: msg));
      return;
    }

    emit(
      state.copyWith(
        status: FormzSubmissionStatus.success,
        updatedUser: res.value,
      ),
    );
  }
}
