import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/use_cases/create_team_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/get_current_team_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/get_teams_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/join_team_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/leave_team_use_case.dart';

part 'teams_event.dart';
part 'teams_state.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  TeamsBloc({
    required String organizationId,
    required String creatorId,
    required GetTeamsUseCase getTeams,
    required CreateTeamUseCase createTeam,
    required JoinTeamUseCase joinTeam,
    required LeaveTeamUseCase leaveTeam,
    required GetCurrentTeamUseCase getCurrentTeam,
  })  : _organizationId = organizationId,
        _creatorId = creatorId,
        _getTeams = getTeams,
        _createTeam = createTeam,
        _joinTeam = joinTeam,
        _leaveTeam = leaveTeam,
        _getCurrentTeam = getCurrentTeam,
        super(const TeamsState()) {
    on<LoadTeams>(_onLoadTeams);
    on<CreateTeam>(_onCreateTeam);
    on<JoinTeam>(_onJoinTeam);
    on<LeaveTeam>(_onLeaveTeam);
  }

  final String _organizationId;
  final String _creatorId;
  final GetTeamsUseCase _getTeams;
  final CreateTeamUseCase _createTeam;
  final JoinTeamUseCase _joinTeam;
  final LeaveTeamUseCase _leaveTeam;
  final GetCurrentTeamUseCase _getCurrentTeam;

  Future<void> _onLoadTeams(
    LoadTeams event,
    Emitter<TeamsState> emit,
  ) async {
    emit(state.copyWith(status: TeamsStatus.loading));

    final teamsResult = await _getTeams(_organizationId);
    final currentTeamResult = await _getCurrentTeam(
      profileId: _creatorId,
      organizationId: _organizationId,
    );

    String? currentTeamId;
    if (currentTeamResult.isSuccess && currentTeamResult.valueOrNull != null) {
      currentTeamId = currentTeamResult.valueOrNull!.id;
    }

    teamsResult.fold(
      (teams) => emit(
        state.copyWith(
          status: TeamsStatus.loaded,
          teams: teams ?? [],
          currentTeamId: currentTeamId,
        ),
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

  Future<void> _onJoinTeam(
    JoinTeam event,
    Emitter<TeamsState> emit,
  ) async {
    emit(state.copyWith(status: TeamsStatus.joining));
    final result = await _joinTeam(
      teamId: event.teamId,
      profileId: _creatorId,
      organizationId: _organizationId,
    );

    result.fold(
      (_) {
        emit(state.copyWith(
          status: TeamsStatus.loaded,
          currentTeamId: event.teamId,
        ));
      },
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  Future<void> _onLeaveTeam(
    LeaveTeam event,
    Emitter<TeamsState> emit,
  ) async {
    emit(state.copyWith(status: TeamsStatus.leaving));
    final result = await _leaveTeam(
      teamId: event.teamId,
      profileId: _creatorId,
    );

    result.fold(
      (_) {
        emit(state.copyWith(
          status: TeamsStatus.loaded,
          clearCurrentTeam: true,
        ));
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
