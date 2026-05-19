part of 'teams_bloc.dart';

enum TeamsStatus { initial, loading, loaded, creating, error }

final class TeamsState extends Equatable {
  const TeamsState({
    this.status = TeamsStatus.initial,
    this.teams = const [],
    this.errorMessage,
  });

  final TeamsStatus status;
  final List<Team> teams;
  final String? errorMessage;

  TeamsState copyWith({
    TeamsStatus? status,
    List<Team>? teams,
    String? errorMessage,
  }) => TeamsState(
    status: status ?? this.status,
    teams: teams ?? this.teams,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, teams, errorMessage];
}
