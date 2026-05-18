part of 'organizations_bloc.dart';

abstract class OrganizationsEvent extends Equatable {
  const OrganizationsEvent();

  @override
  List<Object?> get props => [];
}

class OrganizationsLoadRequested extends OrganizationsEvent {
  const OrganizationsLoadRequested();
}

class OrganizationsCreateRequested extends OrganizationsEvent {
  final String name;
  final String ownerId;

  const OrganizationsCreateRequested({
    required this.name,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [name, ownerId];
}
