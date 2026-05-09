import 'package:get_it/get_it.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/organizations/data/repo/organization_repository_impl.dart';
import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/domain/usecase/update_member_role_usecase.dart';

GetIt sl = GetIt.instance;

void initServiceLocator() {
  // Repositories
  sl.registerSingleton<AuthRepository>(SupabaseAuthRepository(supabase: supabase));
  sl.registerSingleton<UserRepository>(SupabaseUserRepository(supabase: supabase));

  // Organization data source and repository
  sl.registerLazySingleton<OrganizationDataSource>(
    () => OrganizationDataSource(),
  );
  sl.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepositoryImpl(sl<OrganizationDataSource>()),
  );

  // Use cases
  sl.registerFactory<SignInUseCase>(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerFactory<SignUpUseCase>(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerFactory<SignUpWithOrganizationUseCase>(
    () => SignUpWithOrganizationUseCase(
      sl<SignUpUseCase>(),
      sl<GetUserUseCase>(),
      sl<OrganizationRepository>(),
    ),
  );
  sl.registerFactory<SignOutUseCase>(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerFactory<WatchAuthStatusUseCase>(() => WatchAuthStatusUseCase(sl<AuthRepository>()));
  sl.registerFactory<GetUserUseCase>(() => GetUserUseCase(sl<UserRepository>()));
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
  sl.registerFactory<SignUpBloc>(() => SignUpBloc(signUp: sl<SignUpWithOrganizationUseCase>()));
}