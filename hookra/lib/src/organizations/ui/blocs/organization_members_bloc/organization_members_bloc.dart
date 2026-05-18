import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/domain/use_cases/get_organization_details_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/update_member_role_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/update_organization_name_use_case.dart';

part 'organization_members_event.dart';
part 'organization_members_state.dart';

class OrganizationMembersBloc
    extends Bloc<OrganizationMembersEvent, OrganizationMembersState> {
  final GetOrganizationDetailsUseCase _getDetails;
  final UpdateMemberRoleUseCase _updateMemberRole;
  final UpdateOrganizationNameUseCase _updateOrgName;

  OrganizationMembersBloc({
    required GetOrganizationDetailsUseCase getDetails,
    required UpdateMemberRoleUseCase updateMemberRole,
    required UpdateOrganizationNameUseCase updateOrgName,
  }) : _getDetails = getDetails,
       _updateMemberRole = updateMemberRole,
       _updateOrgName = updateOrgName,
       super(const OrganizationMembersState()) {
    on<LoadMembers>(_onLoadMembers);
    on<UpdateMemberRole>(_onUpdateMemberRole);
    on<UpdateOrganizationName>(_onUpdateOrganizationName);
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    emit(state.copyWith(status: OrganizationMembersStatus.loading));

    final result = await _getDetails(event.organizationId);
    if (result.isFailure) {
      emit(
        state.copyWith(
          status: OrganizationMembersStatus.error,
          errorMessage: result.error.toString(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: OrganizationMembersStatus.loaded,
        organization: result.value.organization,
        members: result.value.members,
      ),
    );
  }

  Future<void> _onUpdateMemberRole(
    UpdateMemberRole event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    final previousMembers = List<MemberWithProfile>.from(state.members);

    final optimisticMembers =
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

    emit(state.copyWith(members: optimisticMembers));

    final result = await _updateMemberRole(
      organizationId: event.organizationId,
      profileId: event.profileId,
      newRole: event.newRole,
    );

    if (result.isFailure) {
      emit(
        state.copyWith(
          members: previousMembers,
          status: OrganizationMembersStatus.error,
          errorMessage: result.error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateOrganizationName(
    UpdateOrganizationName event,
    Emitter<OrganizationMembersState> emit,
  ) async {
    final result = await _updateOrgName(
      organizationId: event.organizationId,
      name: event.name,
    );

    if (result.isFailure) {
      emit(
        state.copyWith(
          status: OrganizationMembersStatus.error,
          errorMessage: result.error.toString(),
        ),
      );
      return;
    }

    if (state.organization != null) {
      emit(
        state.copyWith(
          organization: Organization(
            id: state.organization!.id,
            name: event.name,
            slug: state.organization!.slug,
            ownerId: state.organization!.ownerId,
            createdAt: state.organization!.createdAt,
          ),
          status: OrganizationMembersStatus.loaded,
        ),
      );
    }
  }
}
