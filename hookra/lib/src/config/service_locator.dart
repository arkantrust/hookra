import 'package:get_it/get_it.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/authentication/authentication.dart';
import 'package:hookra/src/profile/profile.dart';

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
  sl.registerFactory<SignUpBloc>(
    () => SignUpBloc(authenticationRepository: sl<AuthenticationRepository>()),
  );
  sl.registerFactory<SignInBloc>(
    () => SignInBloc(authenticationRepository: sl<AuthenticationRepository>()),
  );
}
