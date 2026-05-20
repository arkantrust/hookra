import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/profile/domain/use_cases/get_user_use_case.dart';
import 'package:hookra/src/utils/result.dart';

/// Orchestrates the full new-user onboarding flow:
/// sign up → fetch profile → create default organization → add as owner.
///
/// Lives in the onboarding coordination layer so neither `auth` nor
/// `organizations` domains depend on each other.
///
/// Note: org creation + owner membership are two separate DB writes.
/// A single atomic Supabase RPC (`create_organization_with_owner`) would
/// eliminate the partial-write window if `addMember` fails after
/// `createOrganization` succeeds.
class SignUpWithOrganizationUseCase {
  final SignUpUseCase _signUp;
  final GetUserUseCase _getUser;
  final CreateOrganizationUseCase _createOrg;

  SignUpWithOrganizationUseCase(this._signUp, this._getUser, this._createOrg);

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
    if (userResult.isFailure) return Result.failure(userResult.error);
    final user = userResult.value;

    final orgResult = await _createOrg(
      name: "$firstName's Organization",
      ownerId: user.id,
    );
    if (orgResult.isFailure) return Result.failure(orgResult.error);

    return const Result.voidResult();
  }
}
