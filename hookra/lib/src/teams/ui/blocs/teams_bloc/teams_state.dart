part of 'teams_bloc.dart';

enum TeamsStatus { initial, loading, loaded, creating, createSuccess, joining, leaving, deleting, deleteSuccess, error }

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

  static const _sentinel = Object();

  TeamsState copyWith({
    TeamsStatus? status,
    List<Team>? teams,
    String? errorMessage,
    List<String>? memberTeamIds,
    TeamsAction? lastAction,
    Object? lastActionTeamId = _sentinel,
  }) => TeamsState(
    status: status ?? this.status,
    teams: teams ?? this.teams,
    errorMessage: errorMessage ?? this.errorMessage,
    memberTeamIds: memberTeamIds ?? this.memberTeamIds,
    lastAction: lastAction ?? this.lastAction,
    lastActionTeamId: identical(lastActionTeamId, _sentinel)
        ? this.lastActionTeamId
        : lastActionTeamId as String?,
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
