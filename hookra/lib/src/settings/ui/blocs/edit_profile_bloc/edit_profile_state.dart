part of 'edit_profile_bloc.dart';

final class EditProfileState extends Equatable {
  final FormzSubmissionStatus status;
  final Name first;
  final Name last;
  final bool isValid;
  final String error;
  final User? updatedUser;

  const EditProfileState({
    this.status = FormzSubmissionStatus.initial,
    this.first = const Name.pure(),
    this.last = const Name.pure(),
    this.isValid = false,
    this.error = '',
    this.updatedUser,
  });

  EditProfileState copyWith({
    FormzSubmissionStatus? status,
    Name? first,
    Name? last,
    bool? isValid,
    String? error,
    User? updatedUser,
  }) {
    final f = first ?? this.first;
    final l = last ?? this.last;
    return EditProfileState(
      status: status ?? this.status,
      first: f,
      last: l,
      isValid: isValid ?? Formz.validate([f, l]),
      error: error ?? this.error,
      updatedUser: updatedUser ?? this.updatedUser,
    );
  }

  @override
  List<Object?> get props => [status, first, last, isValid, error, updatedUser];
}
