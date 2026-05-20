import 'package:get_it/get_it.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/onboarding/onboarding.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/organizations/data/repo/supabase_invite_repository.dart';
import 'package:hookra/src/organizations/domain/repo/invite_repository.dart';
import 'package:hookra/src/organizations/domain/use_cases/create_invite_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/get_invite_by_token_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/accept_invite_use_case.dart';
import 'package:hookra/src/organizations/ui/blocs/invite_bloc/invite_bloc.dart';

GetIt sl = GetIt.instance;

void initServiceLocator() {
  // Repositories
  sl.registerSingleton<AuthRepository>(
    SupabaseAuthRepository(supabase: supabase),
  );
  sl.registerSingleton<UserRepository>(
    SupabaseUserRepository(supabase: supabase),
  );
  sl.registerSingleton<OrganizationRepository>(
    SupabaseOrganizationRepository(
      supabase: supabase,
      userRepository: sl<UserRepository>(),
    ),
  );
  sl.registerSingleton<InviteRepository>(
    SupabaseInviteRepository(
      supabase: supabase,
      organizationRepository: sl<OrganizationRepository>(),
    ),
  );

  // Use cases
  sl.registerFactory<SignInUseCase>(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerFactory<SignUpUseCase>(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerFactory<SignUpWithOrganizationUseCase>(
    () => SignUpWithOrganizationUseCase(
      sl<SignUpUseCase>(),
      sl<GetUserUseCase>(),
      sl<CreateOrganizationUseCase>(),
    ),
  );
  sl.registerFactory<SignOutUseCase>(
    () => SignOutUseCase(sl<AuthRepository>()),
  );
  sl.registerFactory<WatchAuthStatusUseCase>(
    () => WatchAuthStatusUseCase(sl<AuthRepository>()),
  );
  sl.registerFactory<GetUserUseCase>(
    () => GetUserUseCase(sl<UserRepository>()),
  );
  sl.registerFactory<GetOrganizationsUseCase>(
    () => GetOrganizationsUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<CreateOrganizationUseCase>(
    () => CreateOrganizationUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<GetOrganizationDetailsUseCase>(
    () => GetOrganizationDetailsUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<UpdateOrganizationNameUseCase>(
    () => UpdateOrganizationNameUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<UpdateMemberRoleUseCase>(
    () => UpdateMemberRoleUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<CreateInviteUseCase>(
    () => CreateInviteUseCase(sl<InviteRepository>()),
  );
  sl.registerFactory<GetInviteByTokenUseCase>(
    () => GetInviteByTokenUseCase(sl<InviteRepository>()),
  );
  sl.registerFactory<AcceptInviteUseCase>(
    () => AcceptInviteUseCase(sl<InviteRepository>()),
  );

  // BLoCs
  sl.registerSingleton<AuthBloc>(
    AuthBloc(
      watchStatus: sl<WatchAuthStatusUseCase>(),
      signOut: sl<SignOutUseCase>(),
      getUser: sl<GetUserUseCase>(),
    ),
  );
  sl.registerFactory<SignInBloc>(() => SignInBloc(signIn: sl<SignInUseCase>()));
  sl.registerFactory<SignUpBloc>(
    () => SignUpBloc(signUp: sl<SignUpWithOrganizationUseCase>()),
  );
  sl.registerFactory<OrganizationsBloc>(
    () => OrganizationsBloc(
      getOrganizations: sl<GetOrganizationsUseCase>(),
      createOrganization: sl<CreateOrganizationUseCase>(),
    ),
  );
  sl.registerFactory<OrganizationMembersBloc>(
    () => OrganizationMembersBloc(
      getDetails: sl<GetOrganizationDetailsUseCase>(),
      updateMemberRole: sl<UpdateMemberRoleUseCase>(),
      updateOrgName: sl<UpdateOrganizationNameUseCase>(),
    ),
  );
  sl.registerFactory<InviteBloc>(
    () => InviteBloc(createInvite: sl<CreateInviteUseCase>()),
  );
}
