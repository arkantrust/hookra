import 'package:get_it/get_it.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/authentication/authentication.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/organizations/data/repo/organization_repository_impl.dart';
import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/src/organizations/domain/usecase/update_member_role_usecase.dart';

GetIt sl = GetIt.instance;
void initServiceLocator() {
  sl.registerSingleton<UserRepository>(SupabaseUserRepository(supabase: supabase));
  sl.registerSingleton<AuthenticationRepository>(
    SupabaseAuthenticationRepository(supabase: supabase),
  );
  sl.registerSingleton<AuthenticationBloc>(
    AuthenticationBloc(
      authenticationRepository: sl<AuthenticationRepository>(),
      userRepository: sl<UserRepository>(),
    ),
  );
  sl.registerSingleton<LocationPermissionBloc>(LocationPermissionBloc());
  sl.registerFactory<PositionCubit>(() => PositionCubit());
  sl.registerFactory<SignUpBloc>(
    () => SignUpBloc(authenticationRepository: sl<AuthenticationRepository>()),
  );
  sl.registerFactory<SignInBloc>(
    () => SignInBloc(authenticationRepository: sl<AuthenticationRepository>()),
  );

  sl.registerLazySingleton<OrganizationDataSource>(
    () => OrganizationDataSource(),
  );
  sl.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepositoryImpl(sl<OrganizationDataSource>()),
  );
  sl.registerFactory<UpdateMemberRoleUseCase>(
    () => UpdateMemberRoleUseCase(sl<OrganizationRepository>()),
  );
}
