import 'package:get_it/get_it.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/onboarding/onboarding.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/teams/teams.dart';

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

  sl.registerSingleton<TeamRepository>(
    SupabaseTeamRepository(supabase: supabase),
  );

  sl.registerFactory<GetTeamsUseCase>(
    () => GetTeamsUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<CreateTeamUseCase>(
    () => CreateTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<JoinTeamUseCase>(
    () => JoinTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<LeaveTeamUseCase>(
    () => LeaveTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<GetCurrentTeamUseCase>(
    () => GetCurrentTeamUseCase(sl<TeamRepository>()),
  );

  sl.registerFactoryParam<TeamsBloc, String, String>(
    (organizationId, creatorId) => TeamsBloc(
      organizationId: organizationId,
      creatorId: creatorId,
      getTeams: sl<GetTeamsUseCase>(),
      createTeam: sl<CreateTeamUseCase>(),
      joinTeam: sl<JoinTeamUseCase>(),
      leaveTeam: sl<LeaveTeamUseCase>(),
      getCurrentTeam: sl<GetCurrentTeamUseCase>(),
    ),
  );
}
