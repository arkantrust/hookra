import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/features/organization_roles/domain/model/organization_member.dart';
import 'package:hookra/features/organization_roles/domain/usecases/get_organization_members_usecase.dart';
import 'package:hookra/features/organization_roles/domain/usecases/update_member_role_usecase.dart';

abstract class OrganizationRolesEvent {}

class OrganizationRolesStarted extends OrganizationRolesEvent {}

class OrganizationMemberRoleChanged extends OrganizationRolesEvent {
  final String memberProfileId;
  final OrganizationRole newRole;

  OrganizationMemberRoleChanged({
    required this.memberProfileId,
    required this.newRole,
  });
}

class OrganizationRolesState {
  final bool isLoading;
  final bool isSaving;
  final String? updatingProfileId;
  final String? errorMessage;
  final String organizationId;
  final String currentProfileId;
  final OrganizationRole? currentUserRole;
  final List<OrganizationMember> members;

  const OrganizationRolesState({
    required this.isLoading,
    required this.isSaving,
    required this.updatingProfileId,
    required this.errorMessage,
    required this.organizationId,
    required this.currentProfileId,
    required this.currentUserRole,
    required this.members,
  });

  factory OrganizationRolesState.initial() {
    return const OrganizationRolesState(
      isLoading: false,
      isSaving: false,
      updatingProfileId: null,
      errorMessage: null,
      organizationId: '',
      currentProfileId: '',
      currentUserRole: null,
      members: [],
    );
  }

  OrganizationRolesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? updatingProfileId,
    String? errorMessage,
    String? organizationId,
    String? currentProfileId,
    OrganizationRole? currentUserRole,
    List<OrganizationMember>? members,
    bool clearError = false,
    bool clearUpdatingUser = false,
  }) {
    return OrganizationRolesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      updatingProfileId:
          clearUpdatingUser
              ? null
              : updatingProfileId ?? this.updatingProfileId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      organizationId: organizationId ?? this.organizationId,
      currentProfileId: currentProfileId ?? this.currentProfileId,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      members: members ?? this.members,
    );
  }
}

class OrganizationRolesBloc
    extends Bloc<OrganizationRolesEvent, OrganizationRolesState> {
  OrganizationRolesBloc() : super(OrganizationRolesState.initial()) {
    on<OrganizationRolesStarted>(_onStarted);
    on<OrganizationMemberRoleChanged>(_onRoleChanged);
  }

  final GetOrganizationMembersUsecase _getMembersUsecase =
      GetOrganizationMembersUsecase();
  final UpdateMemberRoleUsecase _updateMemberRoleUsecase =
      UpdateMemberRoleUsecase();

  Future<void> _onStarted(
    OrganizationRolesStarted event,
    Emitter<OrganizationRolesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final context = await _getMembersUsecase.execute();
      emit(
        state.copyWith(
          isLoading: false,
          organizationId: context.organizationId,
          currentProfileId: context.currentProfileId,
          currentUserRole: context.currentUserRole,
          members: context.members,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage:
              'No fue posible cargar los miembros: ${_mapLoadError(e)}',
        ),
      );
    }
  }

  Future<void> _onRoleChanged(
    OrganizationMemberRoleChanged event,
    Emitter<OrganizationRolesState> emit,
  ) async {
    if (state.isSaving ||
        state.organizationId.isEmpty ||
        state.currentUserRole == null) {
      return;
    }

    final candidates = state.members.where(
      (member) => member.profileId == event.memberProfileId,
    );
    if (candidates.isEmpty) {
      return;
    }

    final targetMember = candidates.first;
    emit(
      state.copyWith(
        isSaving: true,
        updatingProfileId: targetMember.profileId,
        clearError: true,
      ),
    );

    try {
      await _updateMemberRoleUsecase.execute(
        organizationId: state.organizationId,
        actorProfileId: state.currentProfileId,
        actorRole: state.currentUserRole!,
        targetMember: targetMember,
        newRole: event.newRole,
      );

      final updatedMembers = state.members
          .map(
            (member) =>
                member.profileId == targetMember.profileId
                    ? member.copyWith(role: event.newRole)
                    : member,
          )
          .toList(growable: false);

      emit(
        state.copyWith(
          isSaving: false,
          clearUpdatingUser: true,
          members: updatedMembers,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          clearUpdatingUser: true,
          errorMessage: _mapUpdateError(e),
        ),
      );
    }
  }

  String _mapLoadError(Object error) {
    final message = error.toString();
    if (message.contains('no pertenece a ninguna organización')) {
      return 'No perteneces a una organización';
    }
    if (message.contains('Usuario no autenticado')) {
      return 'Debes iniciar sesión de nuevo';
    }
    return 'intenta nuevamente';
  }

  String _mapUpdateError(Object error) {
    final message = error.toString();
    if (message.contains('admin solo puede cambiar roles')) {
      return 'Un admin solo puede cambiar roles de miembros';
    }
    if (message.contains('No tienes permisos')) {
      return 'No tienes permisos para cambiar roles';
    }
    return 'No se pudo actualizar el rol';
  }
}
