import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/src/organizations/domain/use_cases/create_organization_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/get_organizations_use_case.dart';

part 'organizations_event.dart';
part 'organizations_state.dart';

class OrganizationsBloc extends Bloc<OrganizationsEvent, OrganizationsState> {
  final GetOrganizationsUseCase _getOrganizations;
  final CreateOrganizationUseCase _createOrganization;

  OrganizationsBloc({
    required GetOrganizationsUseCase getOrganizations,
    required CreateOrganizationUseCase createOrganization,
  }) : _getOrganizations = getOrganizations,
       _createOrganization = createOrganization,
       super(const OrganizationsState()) {
    on<OrganizationsLoadRequested>(_onLoadRequested);
    on<OrganizationsCreateRequested>(_onCreateRequested);
  }

  Future<void> _onLoadRequested(
    OrganizationsLoadRequested event,
    Emitter<OrganizationsState> emit,
  ) async {
    emit(state.copyWith(status: OrganizationsStatus.loading));

    final result = await _getOrganizations();
    if (result.isFailure) {
      emit(
        state.copyWith(
          status: OrganizationsStatus.failure,
          errorMessage: result.error.toString(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: OrganizationsStatus.success,
        organizations: result.value,
      ),
    );
  }

  Future<void> _onCreateRequested(
    OrganizationsCreateRequested event,
    Emitter<OrganizationsState> emit,
  ) async {
    emit(state.copyWith(status: OrganizationsStatus.creating));

    final result = await _createOrganization(
      name: event.name,
      ownerId: event.ownerId,
    );

    if (result.isFailure) {
      emit(
        state.copyWith(
          status: OrganizationsStatus.createFailure,
          errorMessage: result.error.toString(),
        ),
      );
      return;
    }

    add(const OrganizationsLoadRequested());
  }
}
