import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/use_cases/create_team_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/get_teams_use_case.dart';

part 'teams_event.dart';
part 'teams_state.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  TeamsBloc({
    required String organizationId,
    required String creatorId,
    required GetTeamsUseCase getTeams,
    required CreateTeamUseCase createTeam,
  })  : _organizationId = organizationId,
        _creatorId = creatorId,
        _getTeams = getTeams,
        _createTeam = createTeam,
        super(const TeamsState()) {
    on<LoadTeams>(_onLoadTeams);
    on<CreateTeam>(_onCreateTeam);
  }

  final String _organizationId;
  final String _creatorId;
  final GetTeamsUseCase _getTeams;
  final CreateTeamUseCase _createTeam;

  Future<void> _onLoadTeams(
    LoadTeams event,
    Emitter<TeamsState> emit,
  ) async {
    emit(state.copyWith(status: TeamsStatus.loading));
    final result = await _getTeams(_organizationId);
    result.fold(
      (teams) => emit(
        state.copyWith(status: TeamsStatus.loaded, teams: teams ?? []),
      ),
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  Future<void> _onCreateTeam(
    CreateTeam event,
    Emitter<TeamsState> emit,
  ) async {
    emit(state.copyWith(status: TeamsStatus.creating));
    final result = await _createTeam(
      organizationId: _organizationId,
      name: event.name,
      creatorProfileId: _creatorId,
    );
    result.fold(
      (team) {
        final updated = [if (team != null) team, ...state.teams];
        emit(state.copyWith(status: TeamsStatus.loaded, teams: updated));
      },
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
        ),
      ),
    );
  }
}
