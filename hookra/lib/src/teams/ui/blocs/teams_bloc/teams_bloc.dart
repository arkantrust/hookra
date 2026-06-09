import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/teams/domain/entities/team.dart';
import 'package:hookra/src/teams/domain/use_cases/create_team_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/delete_team_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/get_teams_use_case.dart';
import 'package:hookra/src/teams/domain/use_cases/get_user_team_ids_use_case.dart';
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
    required DeleteTeamUseCase deleteTeam,
    required JoinTeamUseCase joinTeam,
    required LeaveTeamUseCase leaveTeam,
    required GetUserTeamIdsUseCase getUserTeamIds,
  }) : _organizationId = organizationId,
       _creatorId = creatorId,
       _getTeams = getTeams,
       _createTeam = createTeam,
       _deleteTeam = deleteTeam,
       _joinTeam = joinTeam,
       _leaveTeam = leaveTeam,
       _getUserTeamIds = getUserTeamIds,
       super(const TeamsState()) {
    on<LoadTeams>(_onLoadTeams);
    on<CreateTeam>(_onCreateTeam);
    on<DeleteTeam>(_onDeleteTeam);
    on<JoinTeam>(_onJoinTeam);
    on<LeaveTeam>(_onLeaveTeam);
  }

  final String _organizationId;
  final String _creatorId;
  final GetTeamsUseCase _getTeams;
  final CreateTeamUseCase _createTeam;
  final DeleteTeamUseCase _deleteTeam;
  final JoinTeamUseCase _joinTeam;
  final LeaveTeamUseCase _leaveTeam;
  final GetUserTeamIdsUseCase _getUserTeamIds;

  Future<void> _onLoadTeams(LoadTeams event, Emitter<TeamsState> emit) async {
    emit(
      state.copyWith(
        status: TeamsStatus.loading,
        lastAction: TeamsAction.none,
        lastActionTeamId: null,
      ),
    );

    final teamsResult = await _getTeams(_organizationId);
    if (teamsResult.isFailure) {
      emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: teamsResult.error.toString(),
          lastAction: TeamsAction.none,
          lastActionTeamId: null,
        ),
      );
      return;
    }

    final memberTeamsResult = await _getUserTeamIds(
      profileId: _creatorId,
      organizationId: _organizationId,
    );

    if (memberTeamsResult.isFailure) {
      emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: memberTeamsResult.error.toString(),
          lastAction: TeamsAction.none,
          lastActionTeamId: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: TeamsStatus.loaded,
        teams: teamsResult.value,
        memberTeamIds: memberTeamsResult.value,
        lastAction: TeamsAction.none,
        lastActionTeamId: null,
      ),
    );
  }

  Future<void> _onCreateTeam(CreateTeam event, Emitter<TeamsState> emit) async {
    emit(
      state.copyWith(
        status: TeamsStatus.creating,
        lastAction: TeamsAction.none,
        lastActionTeamId: null,
      ),
    );
    final result = await _createTeam(
      organizationId: _organizationId,
      name: event.name,
      creatorProfileId: _creatorId,
    );
    result.fold(
      (team) {
        final updatedTeams = [?team, ...state.teams];
        final updatedMemberIds = {
          ...state.memberTeamIds,
          if (team != null) team.id,
        }.toList();
        emit(
          state.copyWith(
            status: TeamsStatus.createSuccess,
            teams: updatedTeams,
            memberTeamIds: updatedMemberIds,
            lastAction: TeamsAction.none,
            lastActionTeamId: null,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
          lastAction: TeamsAction.none,
          lastActionTeamId: null,
        ),
      ),
    );
  }

  Future<void> _onDeleteTeam(DeleteTeam event, Emitter<TeamsState> emit) async {
    emit(state.copyWith(status: TeamsStatus.deleting));

    final result = await _deleteTeam(event.teamId);
    result.fold(
      (_) {
        final updatedTeams = state.teams.where((t) => t.id != event.teamId).toList();
        final updatedMemberIds = List<String>.from(state.memberTeamIds)
          ..remove(event.teamId);
        emit(
          state.copyWith(
            status: TeamsStatus.deleteSuccess,
            teams: updatedTeams,
            memberTeamIds: updatedMemberIds,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  Future<void> _onJoinTeam(JoinTeam event, Emitter<TeamsState> emit) async {
    emit(
      state.copyWith(
        status: TeamsStatus.joining,
        lastAction: TeamsAction.none,
        lastActionTeamId: null,
      ),
    );
    final result = await _joinTeam(
      teamId: event.teamId,
      profileId: _creatorId,
      organizationId: _organizationId,
    );

    result.fold(
      (_) {
        final updatedMemberIds = {
          ...state.memberTeamIds,
          event.teamId,
        }.toList();
        emit(
          state.copyWith(
            status: TeamsStatus.loaded,
            memberTeamIds: updatedMemberIds,
            lastAction: TeamsAction.joined,
            lastActionTeamId: event.teamId,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
          lastAction: TeamsAction.none,
          lastActionTeamId: null,
        ),
      ),
    );
  }

  Future<void> _onLeaveTeam(LeaveTeam event, Emitter<TeamsState> emit) async {
    emit(
      state.copyWith(
        status: TeamsStatus.leaving,
        lastAction: TeamsAction.none,
        lastActionTeamId: null,
      ),
    );
    final result = await _leaveTeam(
      teamId: event.teamId,
      profileId: _creatorId,
    );

    result.fold(
      (_) {
        final updatedMemberIds = List<String>.from(state.memberTeamIds)
          ..remove(event.teamId);
        emit(
          state.copyWith(
            status: TeamsStatus.loaded,
            memberTeamIds: updatedMemberIds,
            lastAction: TeamsAction.left,
            lastActionTeamId: event.teamId,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          status: TeamsStatus.error,
          errorMessage: error.toString(),
          lastAction: TeamsAction.none,
          lastActionTeamId: null,
        ),
      ),
    );
  }
}
