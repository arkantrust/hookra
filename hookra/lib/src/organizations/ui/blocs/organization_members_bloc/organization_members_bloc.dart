import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/domain/use_cases/update_member_role_use_case.dart';

part 'organization_members_event.dart';
part 'organization_members_state.dart';

class OrganizationMembersBloc
    extends Bloc<OrganizationMembersEvent, OrganizationMembersState> {
  final OrganizationRepository _repository;
  final UpdateMemberRoleUseCase _updateMemberRoleUseCase;

  OrganizationMembersBloc({
    required OrganizationRepository repository,
    required UpdateMemberRoleUseCase updateMemberRoleUseCase,
  }) : _repository = repository,
       _updateMemberRoleUseCase = updateMemberRoleUseCase,
       super(const OrganizationMembersState()) {
    on<LoadMembers>(_onLoadMembers);
    on<UpdateMemberRole>(_onUpdateMemberRole);
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    emit(state.copyWith(status: OrganizationMembersStatus.loading));

    try {
      final organization = await _repository.getOrganizationById(
        event.organizationId,
      );
      final members = await _repository.getOrganizationMembers(
        event.organizationId,
      );

      emit(
        state.copyWith(
          status: OrganizationMembersStatus.loaded,
          organization: organization,
          members: members,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OrganizationMembersStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateMemberRole(
    UpdateMemberRole event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    final previousMembers = List<MemberWithProfile>.from(state.members);

    final updatedMembers =
        state.members.map((m) {
          if (m.profileId == event.profileId) {
            return MemberWithProfile(
              profileId: m.profileId,
              firstName: m.firstName,
              lastName: m.lastName,
              email: m.email,
              role: event.newRole,
            );
          }
          return m;
        }).toList();

    emit(state.copyWith(members: updatedMembers));

    final result = await _updateMemberRoleUseCase(
      organizationId: event.organizationId,
      profileId: event.profileId,
      newRole: event.newRole,
    );

    if (result.isFailure) {
      emit(state.copyWith(members: previousMembers));
    }
  }
}
