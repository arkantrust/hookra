part of 'selection_cubit.dart';

enum SelectionStatus { initial, loading, ready, failure }

class SelectionState extends Equatable {
  final SelectionStatus status;
  final List<OrganizationWithRole> orgs;
  final List<Team> teams;
  final String? selectedOrgId;
  final String? selectedTeamId;
  final bool teamsLoading;
  final String? error;

  const SelectionState({
    this.status = SelectionStatus.initial,
    this.orgs = const [],
    this.teams = const [],
    this.selectedOrgId,
    this.selectedTeamId,
    this.teamsLoading = false,
    this.error,
  });

  /// The currently selected organization, or null if none/unknown.
  OrganizationWithRole? get selectedOrg {
    for (final o in orgs) {
      if (o.organization.id == selectedOrgId) return o;
    }
    return null;
  }

  /// The currently selected team, or null if none/unknown.
  Team? get selectedTeam {
    for (final t in teams) {
      if (t.id == selectedTeamId) return t;
    }
    return null;
  }

  SelectionState copyWith({
    SelectionStatus? status,
    List<OrganizationWithRole>? orgs,
    List<Team>? teams,
    String? selectedOrgId,
    String? selectedTeamId,
    bool clearTeam = false,
    bool? teamsLoading,
    String? error,
  }) {
    return SelectionState(
      status: status ?? this.status,
      orgs: orgs ?? this.orgs,
      teams: teams ?? this.teams,
      selectedOrgId: selectedOrgId ?? this.selectedOrgId,
      selectedTeamId: clearTeam
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      teamsLoading: teamsLoading ?? this.teamsLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orgs,
    teams,
    selectedOrgId,
    selectedTeamId,
    teamsLoading,
    error,
  ];
}
