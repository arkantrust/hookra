part of 'teams_bloc.dart';

sealed class TeamsEvent extends Equatable {
  const TeamsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadTeams extends TeamsEvent {
  const LoadTeams();
}

final class CreateTeam extends TeamsEvent {
  const CreateTeam(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class JoinTeam extends TeamsEvent {
  const JoinTeam(this.teamId);

  final String teamId;

  @override
  List<Object?> get props => [teamId];
}

final class LeaveTeam extends TeamsEvent {
  const LeaveTeam(this.teamId);

  final String teamId;

  @override
  List<Object?> get props => [teamId];
}
