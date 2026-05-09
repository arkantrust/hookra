import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/utils/result.dart';

class UpdateMemberRoleUseCase {
  final OrganizationRepository _repository;

  UpdateMemberRoleUseCase(this._repository);

  Future<Result<void>> call({
    required String memberId,
    required OrgRole newRole,
  }) async {
    try {
      await _repository.updateMemberRole(memberId, newRole);
      return const Result.voidResult();
    } catch (e, s) {
      return Result.unknown(
        name: 'UpdateMemberRoleUseCase',
        error: e,
        stackTrace: s,
      );
    }
  }
}