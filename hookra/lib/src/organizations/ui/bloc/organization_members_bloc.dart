import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/auth/can_change_role.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/domain/usecase/update_member_role_usecase.dart';

part 'organization_members_event.dart';
part 'organization_members_state.dart';

class OrganizationMembersBloc
    extends Bloc<OrganizationMembersEvent, OrganizationMembersState> {
  final OrganizationRepository _repository;
  final UpdateMemberRoleUseCase _updateRoleUseCase;
  String? _currentUserProfileId;

  OrganizationMembersBloc({
    required OrganizationRepository repository,
    required UpdateMemberRoleUseCase updateRoleUseCase,
    String? currentUserProfileId,
  })  : _repository = repository,
        _updateRoleUseCase = updateRoleUseCase,
        _currentUserProfileId = currentUserProfileId,
        super(const OrganizationMembersState()) {
    on<LoadOrganizationMembers>(_onLoadMembers);
    on<UpdateMemberRole>(_onUpdateRole);
  }

  Future<void> _onLoadMembers(
    LoadOrganizationMembers event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    emit(state.copyWith(status: OrganizationMembersStatus.loading));

    try {
      final members = await _repository.getMembers(event.organizationId);
      final organization =
          await _repository.getOrganization(event.organizationId);

      // Get current user role from members list
      OrgRole? currentUserRole;
      if (_currentUserProfileId != null) {
        currentUserRole = members
            .where((m) => m.profileId == _currentUserProfileId)
            .firstOrNull
            ?.role;
      }

      emit(state.copyWith(
        status: OrganizationMembersStatus.loaded,
        members: members,
        organization: organization,
        currentUserRole: currentUserRole,
      ));
    } catch (e, st) {
      print('DEBUG BLoC: Error: $e');
      print('DEBUG BLoC: StackTrace: $st');
      emit(state.copyWith(
        status: OrganizationMembersStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateRole(
    UpdateMemberRole event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    print('DEBUG BLoC: _onUpdateRole - memberId: ${event.memberId}, newRole: ${event.newRole}');
    
    final member = state.members.firstWhere((m) => m.id == event.memberId);
    final previousRole = member.role;
    final organization = state.organization;
    
    print('DEBUG BLoC: current user role: ${state.currentUserRole}');
    print('DEBUG BLoC: target role: ${member.role}');
    print('DEBUG BLoC: org owner: ${organization?.ownerId}');

    if (organization == null) return;

    final canChange = canChangeRole(
      actorRole: state.currentUserRole ?? OrgRole.member,
      targetRole: previousRole,
      targetProfileId: member.profileId,
      organizationOwnerId: organization.ownerId,
    );

    print('DEBUG BLoC: canChange: $canChange');

    if (!canChange) {
      emit(state.copyWith(
        error: 'No tienes permiso para cambiar este rol',
      ));
      return;
    }

    final updatedMembers = state.members.map((m) {
      if (m.id == event.memberId) {
        return m.copyWith(role: event.newRole);
      }
      return m;
    }).toList();

    emit(state.copyWith(
      status: OrganizationMembersStatus.updating,
      members: updatedMembers,
      updatingMemberId: event.memberId,
    ));

    print('DEBUG BLoC: calling useCase...');
    final result = await _updateRoleUseCase(
      memberId: event.memberId,
      newRole: event.newRole,
    );
    print('DEBUG BLoC: useCase result: ${result.isSuccess}');

    if (result.isFailure) {
      print('DEBUG BLoC: update failed');
      final rolledBackMembers = state.members.map((m) {
        if (m.id == event.memberId) {
          return m.copyWith(role: previousRole);
        }
        return m;
      }).toList();

      emit(state.copyWith(
        status: OrganizationMembersStatus.error,
        members: rolledBackMembers,
        updatingMemberId: null,
        error: 'Error al cambiar el rol. Intenta de nuevo.',
      ));
    } else {
      print('DEBUG BLoC: update success');
      emit(state.copyWith(
        status: OrganizationMembersStatus.loaded,
        updatingMemberId: null,
      ));
    }
  }
}