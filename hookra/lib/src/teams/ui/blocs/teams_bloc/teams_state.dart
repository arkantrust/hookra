part of 'teams_bloc.dart';

enum TeamsStatus {
  initial,
  loading,
  loaded,
  creating,
  joining,
  leaving,
  error,
}

final class TeamsState extends Equatable {
  const TeamsState({
    this.status = TeamsStatus.initial,
    this.teams = const [],
    this.errorMessage,
    this.currentTeamId,
  });

  final TeamsStatus status;
  final List<Team> teams;
  final String? errorMessage;
  final String? currentTeamId;

  bool isInTeam(String teamId) => currentTeamId == teamId;

  bool get isInAnyTeam => currentTeamId != null;

  TeamsState copyWith({
    TeamsStatus? status,
    List<Team>? teams,
    String? errorMessage,
    String? currentTeamId,
    bool clearCurrentTeam = false,
  }) =>
      TeamsState(
        status: status ?? this.status,
        teams: teams ?? this.teams,
        errorMessage: errorMessage ?? this.errorMessage,
        currentTeamId:
            clearCurrentTeam ? null : (currentTeamId ?? this.currentTeamId),
      );

  @override
  List<Object?> get props => [status, teams, errorMessage, currentTeamId];
}
