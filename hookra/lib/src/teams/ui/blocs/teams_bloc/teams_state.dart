part of 'teams_bloc.dart';

enum TeamsStatus { initial, loading, loaded, creating, joining, leaving, error }

enum TeamsAction { none, joined, left }

final class TeamsState extends Equatable {
  const TeamsState({
    this.status = TeamsStatus.initial,
    this.teams = const [],
    this.errorMessage,
    this.memberTeamIds = const [],
    this.lastAction = TeamsAction.none,
    this.lastActionTeamId,
  });

  final TeamsStatus status;
  final List<Team> teams;
  final String? errorMessage;
  final List<String> memberTeamIds;
  final TeamsAction lastAction;
  final String? lastActionTeamId;

  bool isInTeam(String teamId) => memberTeamIds.contains(teamId);

  bool get isInAnyTeam => memberTeamIds.isNotEmpty;

  TeamsState copyWith({
    TeamsStatus? status,
    List<Team>? teams,
    String? errorMessage,
    List<String>? memberTeamIds,
    TeamsAction? lastAction,
    String? lastActionTeamId,
  }) => TeamsState(
    status: status ?? this.status,
    teams: teams ?? this.teams,
    errorMessage: errorMessage ?? this.errorMessage,
    memberTeamIds: memberTeamIds ?? this.memberTeamIds,
    lastAction: lastAction ?? this.lastAction,
    lastActionTeamId: lastActionTeamId ?? this.lastActionTeamId,
  );

  @override
  List<Object?> get props => [
    status,
    teams,
    errorMessage,
    memberTeamIds,
    lastAction,
    lastActionTeamId,
  ];
}
