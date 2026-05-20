part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object> get props => [];
}

final class EditProfileFirstChanged extends EditProfileEvent {
  const EditProfileFirstChanged(this.first);

  final String first;

  @override
  List<Object> get props => [first];
}

final class EditProfileLastChanged extends EditProfileEvent {
  const EditProfileLastChanged(this.last);

  final String last;

  @override
  List<Object> get props => [last];
}

final class EditProfileSubmitted extends EditProfileEvent {
  const EditProfileSubmitted();
}
