import 'package:hookra/src/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/profile/domain/use_cases/get_user_use_case.dart';
import 'package:hookra/src/utils/result.dart';

/// {@template sign_up_with_organization_use_case}
/// Signs the user up, then creates a default organization named
/// `"{firstName}'s Organization"` and adds the user as owner.
///
/// TODO: Org creation + owner membership should be a single atomic
/// Supabase RPC (e.g. `create_organization_with_owner`). Right now if
/// `addMember` fails after `createOrganization` succeeds, we leak an
/// org with no owner. Out of scope for this change.
/// {@endtemplate}
class SignUpWithOrganizationUseCase {
  final SignUpUseCase _signUp;
  final GetUserUseCase _getUser;
  final OrganizationRepository _orgs;

  SignUpWithOrganizationUseCase(this._signUp, this._getUser, this._orgs);

  Future<Result<void>> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final signUpResult = await _signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    if (signUpResult.isFailure) return signUpResult;

    final userResult = await _getUser();
    if (userResult.isFailure) {
      return Result.failure(userResult.error);
    }
    final user = userResult.value;

    try {
      final org = await _orgs.createOrganization(
        "$firstName's Organization",
        user.id,
      );
      await _orgs.addMember(org.id, user.id, 'owner');
      return Result.voidResult();
    } on Exception catch (e, st) {
      return Result.unknown(
        name: 'SignUpWithOrganizationUseCase',
        error: e,
        stackTrace: st,
      );
    }
  }
}
