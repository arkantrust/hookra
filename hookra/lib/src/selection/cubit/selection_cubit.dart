import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/teams/teams.dart';

part 'selection_state.dart';

/// Holds the user's active organization/team selection in memory.
///
/// App-global singleton: any screen can read the active context. The selection
/// is ephemeral — it is not persisted, so it resets on app restart and is
/// cleared on sign-out via [clear].
class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit({
    required this._getOrganizations,
    required GetTeamsUseCase getTeams,
  }) : _getTeams = getTeams,
       super(const SelectionState());

  final GetOrganizationsUseCase _getOrganizations;
  final GetTeamsUseCase _getTeams;

  /// Loads the user's organizations and the teams of the resolved active org.
  ///
  /// No-op once a load has already started (guarded on [SelectionStatus.initial])
  /// so it is safe to call from a widget's `initState`.
  Future<void> load({String? initialOrgId, String? initialTeamId}) async {
    if (state.status != SelectionStatus.initial) return;
    emit(state.copyWith(status: SelectionStatus.loading));

    final orgsResult = await _getOrganizations();
    if (orgsResult.isFailure) {
      emit(
        state.copyWith(
          status: SelectionStatus.failure,
          error: orgsResult.error.toString(),
        ),
      );
      return;
    }

    final orgs = orgsResult.value;
    final selectedOrgId = _resolveInitialOrgId(orgs, initialOrgId);

    if (selectedOrgId == null) {
      emit(state.copyWith(status: SelectionStatus.ready, orgs: orgs));
      return;
    }

    final teamsResult = await _getTeams(selectedOrgId);
    final teams = teamsResult.isSuccess ? teamsResult.value : const <Team>[];

    emit(
      state.copyWith(
        status: SelectionStatus.ready,
        orgs: orgs,
        teams: teams,
        selectedOrgId: selectedOrgId,
        selectedTeamId: initialTeamId,
      ),
    );
  }

  /// Selects [orgId] as the active organization and reloads its teams,
  /// clearing any previously selected team.
  Future<void> selectOrg(String orgId) async {
    if (orgId == state.selectedOrgId) return;
    emit(state.copyWith(selectedOrgId: orgId, clearTeam: true, teamsLoading: true));

    final teamsResult = await _getTeams(orgId);
    emit(
      state.copyWith(
        teams: teamsResult.isSuccess ? teamsResult.value : const <Team>[],
        teamsLoading: false,
      ),
    );
  }

  /// Selects [teamId] as the active team within the current organization.
  void selectTeam(String teamId) =>
      emit(state.copyWith(selectedTeamId: teamId));

  /// Resets the selection (used on sign-out).
  void clear() => emit(const SelectionState());

  String? _resolveInitialOrgId(
    List<OrganizationWithRole> orgs,
    String? initialOrgId,
  ) {
    if (orgs.isEmpty) return null;
    final exists =
        initialOrgId != null &&
        orgs.any((o) => o.organization.id == initialOrgId);
    return exists ? initialOrgId : orgs.first.organization.id;
  }
}
