# Specifications — Clean Architecture Migration (specs_clean_arch.md)

Este documento define las especificaciones de implementación para **Login** y **Sign Up** siguiendo la arquitectura Clean Architecture + BLoC establecida en las reglas del proyecto. Es un documento prescriptivo: define qué construir y cómo, no lo que existe hoy.

> Sin geolocalización. Sin GoRouter. Sin formz. Sin get_it. Sin freezed.
> Patrón: `UI → BLoC → UseCase → RepoInterface → RepoImpl → DataSource → Supabase`

---

## 1. Feature: Sign Up (Registro)

### Objetivo
Permitir a nuevos usuarios crear una cuenta con nombre, apellido, email y contraseña. El `SignupUsecase` combina dos responsabilidades: crear el usuario en Supabase Auth (pasando el nombre como metadata para el trigger de BD) y hacer upsert del perfil en la tabla `profiles`.

### User Stories
- **Como** nuevo usuario, **quiero** registrarme con mis datos básicos **para** acceder a las funcionalidades protegidas de la app.
- **Como** nuevo usuario, **quiero** confirmar mi contraseña **para** evitar errores de tipeo.
- **Como** nuevo usuario, **quiero** recibir mensajes claros si mi registro falla **para** saber qué corregir.

### Requerimientos Funcionales

- **Entradas:**

  | Campo | Validación | Modo |
  |---|---|---|
  | Nombre (`firstName`) | No vacío | Al submit |
  | Apellido (`lastName`) | No vacío | Al submit |
  | Email (`email`) | Contiene `@` | Tiempo real (`onUserInteraction`) |
  | Contraseña (`password`) | Mínimo 8 caracteres | Tiempo real (`onUserInteraction`) |
  | Confirmar contraseña (`confirmPassword`) | Igual a `password` | Al submit |

- **Acciones:**
  1. `SignupScreen` valida con `GlobalKey<FormState>` antes de disparar el evento.
  2. Dispara `SignupSubmitEvent` → `SignupBloc`.
  3. `SignupBloc` llama a `SignupUsecase.execute(firstName, lastName, email, password)`.
  4. `SignupUsecase` llama a `AuthRepo.signup(email, password, firstName, lastName)` → obtiene `userId`.
  5. `AuthDataSource` pasa `data: {'first_name': firstName, 'last_name': lastName}` al `signUp` de Supabase para que el trigger de BD pueda crear el perfil correctamente.
  6. Con `userId`, `SignupUsecase` llama a `ProfileRepository.saveProfile(Profile(...))`.
  7. `ProfileDataSource` usa **upsert** (no insert) para que si el trigger ya creó el perfil, se actualice sin error de clave duplicada.
  8. `SignupBloc` emite `SignupLoadingState` → `SignupSuccessState` o `SignupFailState(message)`.
  9. `BlocListener` navega a `/home` en éxito, muestra `SnackBar` en fallo.

- **Errores a manejar:**

  | Caso | Mensaje |
  |---|---|
  | Email ya registrado | `'Este correo ya está registrado'` |
  | Contraseña muy débil (Supabase) | `'La contraseña es muy débil'` |
  | Sin conexión | `'No estás conectado a internet'` |
  | Error desconocido | `'Error: $error'` (raw para diagnóstico) |

  > **Nota técnica:** El error `AuthRetryableFetchException` con `"Database error saving new user"` (500) ocurre cuando el trigger de Supabase falla al crear el perfil porque no recibe `first_name`/`last_name` en el metadata. La solución es pasar ese metadata en el `signUp`.

### Estructura de archivos

```
lib/features/auth/
  domain/
    repo/
      auth_repo.dart                 # abstract class AuthRepo
    usecases/
      signup_usecase.dart            # combina AuthRepo + ProfileRepository
  data/
    sources/
      auth_data_source.dart          # único archivo con supabase_flutter
    repo/
      auth_repo_impl.dart            # implementa AuthRepo, extrae userId

lib/features/profile/
  domain/
    model/
      profile.dart                   # clase Dart pura
    repo/
      profile_repository.dart        # abstract class ProfileRepository
  data/
    sources/
      profile_data_source.dart       # UPSERT en tabla 'profiles'
    repo/
      profile_repository_impl.dart   # implementa ProfileRepository

lib/features/auth/
  ui/
    bloc/
      signup_bloc.dart               # eventos + estados + BLoC en UN archivo
    screens/
      signup_screen.dart
```

### Contratos

**`lib/features/profile/domain/model/profile.dart`**
```dart
class Profile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
  };
}
```

**`lib/features/auth/domain/repo/auth_repo.dart`**
```dart
abstract class AuthRepo {
  Future<String> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  );
  Future<void> login(String email, String password);
}
```

**`lib/features/profile/domain/repo/profile_repository.dart`**
```dart
abstract class ProfileRepository {
  Future<void> saveProfile(Profile profile);
}
```

**`lib/features/auth/domain/usecases/signup_usecase.dart`**
```dart
class SignupUsecase {
  AuthRepo authRepo = AuthRepoImpl();
  ProfileRepository profileRepo = ProfileRepositoryImpl();

  Future<void> execute(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final userId = await authRepo.signup(email, password, firstName, lastName);
    await profileRepo.saveProfile(
      Profile(id: userId, firstName: firstName, lastName: lastName, email: email),
    );
  }
}
```

**`lib/features/auth/data/sources/auth_data_source.dart`**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDataSource {
  Future<AuthResponse> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName, 'last_name': lastName},
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```

**`lib/features/auth/data/repo/auth_repo_impl.dart`**
```dart
class AuthRepoImpl extends AuthRepo {
  final AuthDataSource _source = AuthDataSource();

  @override
  Future<String> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    final response = await _source.signup(email, password, firstName, lastName);
    return response.user!.id;
  }

  @override
  Future<void> login(String email, String password) async {
    await _source.login(email, password);
  }
}
```

**`lib/features/profile/data/sources/profile_data_source.dart`**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDataSource {
  Future<void> saveProfile(Map<String, dynamic> data) async {
    await Supabase.instance.client.from('profiles').upsert(data);
  }
}
```

**`lib/features/profile/data/repo/profile_repository_impl.dart`**
```dart
class ProfileRepositoryImpl extends ProfileRepository {
  final ProfileDataSource _source = ProfileDataSource();

  @override
  Future<void> saveProfile(Profile profile) async {
    await _source.saveProfile(profile.toJson());
  }
}
```

### BLoC — `lib/features/auth/ui/bloc/signup_bloc.dart`

```dart
// Events
abstract class SignupEvent {}

class SignupSubmitEvent extends SignupEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  SignupSubmitEvent({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });
}

// States
abstract class SignupState {}
class SignupInitialState extends SignupState {}
class SignupLoadingState extends SignupState {}
class SignupSuccessState extends SignupState {}
class SignupFailState extends SignupState {
  final String message;
  SignupFailState(this.message);
}

// BLoC
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupUsecase signupUsecase = SignupUsecase();

  SignupBloc() : super(SignupInitialState()) {
    on<SignupSubmitEvent>((event, emit) async {
      emit(SignupLoadingState());
      try {
        await signupUsecase.execute(
          event.firstName,
          event.lastName,
          event.email,
          event.password,
        );
        emit(SignupSuccessState());
      } catch (e) {
        emit(SignupFailState(_mapError(e.toString())));
      }
    });
  }

  String _mapError(String error) {
    if (error.contains('already')) return 'Este correo ya está registrado';
    if (error.contains('weak')) return 'La contraseña es muy débil';
    if (error.contains('network') || error.contains('socket')) {
      return 'No estás conectado a internet';
    }
    return 'Error: $error';
  }
}
```

### Routing — `main.dart`

```dart
routes: {
  '/login': (_) => BlocProvider(
    create: (_) => LoginBloc(),
    child: const LoginScreen(),
  ),
  '/signup': (_) => BlocProvider(
    create: (_) => SignupBloc(),
    child: const SignupScreen(),
  ),
  '/home': (_) => const HomeScreen(),
},
initialRoute: '/login',
```

### Acceptance Criteria

- [x] `profile.dart` — clase Dart pura, solo `toJson()`. Cero imports de Flutter o Supabase.
- [x] `auth_repo.dart` — interfaz abstracta con `signup(email, password, firstName, lastName)`. Cero imports de Supabase.
- [x] `profile_repository.dart` — interfaz abstracta. Cero imports de Supabase.
- [x] `auth_data_source.dart` — **único** archivo que importa `supabase_flutter`. Pasa `data: {'first_name', 'last_name'}` al `signUp`. Devuelve `AuthResponse` crudo.
- [x] `profile_data_source.dart` — usa `upsert` (no `insert`). Sin mapeo a `Profile`.
- [x] `auth_repo_impl.dart` — no importa `supabase_flutter`. Extrae `response.user!.id`.
- [x] `profile_repository_impl.dart` — no importa `supabase_flutter`. Llama a `_source.saveProfile(profile.toJson())`.
- [x] `signup_usecase.dart` — combina `AuthRepo` + `ProfileRepository`. Sin imports de Flutter ni Supabase.
- [x] `signup_bloc.dart` — eventos, estados y BLoC en **un solo archivo**.
- [x] Estados: `Initial → Loading → Success / Fail`.
- [x] `SignupScreen` — `GlobalKey<FormState>` valida antes de disparar el evento.
- [x] `SignupScreen` — `BlocListener` navega a `/home` en `SignupSuccessState`.
- [x] `SignupScreen` — `BlocListener` muestra `SnackBar` en `SignupFailState`.
- [x] `SignupScreen` — `BlocBuilder` muestra `CircularProgressIndicator` en `SignupLoadingState`.
- [x] Campo email — `autovalidateMode: AutovalidateMode.onUserInteraction`. Mensaje: `'Falta el @'`.
- [x] Campo contraseña — `autovalidateMode: AutovalidateMode.onUserInteraction`. Mensaje: `'Mínimo 8 caracteres'`.
- [x] Botón con toggle show/hide contraseña (`Icons.visibility` / `Icons.visibility_off`).
- [x] Botón con toggle show/hide confirmar contraseña (independiente del anterior).
- [x] Link "¿Ya tienes cuenta? Inicia sesión" navega a `/login`.
- [x] Ruta `/signup` con `BlocProvider<SignupBloc>` en `main.dart`.

---

## 2. Feature: Login

### Objetivo
Permitir a usuarios existentes iniciar sesión con email y contraseña, persistiendo la sesión en Supabase.

### User Stories
- **Como** usuario registrado, **quiero** iniciar sesión con mi email y contraseña **para** retomar mi actividad.
- **Como** usuario, **quiero** mensajes de error claros **para** saber qué está fallando.
- **Como** usuario nuevo, **quiero** poder navegar al registro desde el login **para** crear mi cuenta.

### Requerimientos Funcionales

- **Entradas:**

  | Campo | Validación | Modo |
  |---|---|---|
  | Email (`email`) | Contiene `@` | Tiempo real (`onUserInteraction`) |
  | Contraseña (`password`) | No vacío | Al submit |

- **Acciones:**
  1. `LoginScreen` valida con `GlobalKey<FormState>`.
  2. Dispara `LoginSubmitEvent` → `LoginBloc`.
  3. `LoginBloc` llama a `LoginUsecase.execute(email, password)`.
  4. `LoginUsecase` llama a `AuthRepo.login(email, password)`.
  5. `AuthDataSource` llama a `supabase.auth.signInWithPassword(...)`.
  6. `LoginBloc` emite `LoginLoadingState` → `LoginSuccessState` o `LoginFailState(message)`.
  7. `BlocListener` navega a `/home` en éxito, muestra `SnackBar` en fallo.

- **Errores a manejar:**

  | Caso | Mensaje |
  |---|---|
  | Credenciales inválidas | `'Email o contraseña incorrectos'` |
  | Sin conexión | `'No estás conectado a internet'` |
  | Error desconocido | `'Error: $error'` (raw para diagnóstico) |

### Estructura de archivos

```
lib/features/auth/
  domain/
    repo/
      auth_repo.dart              # (mismo que Sign Up — compartido)
    usecases/
      login_usecase.dart          # un archivo, un caso de uso
  data/
    sources/
      auth_data_source.dart       # (mismo que Sign Up — agrega login)
    repo/
      auth_repo_impl.dart         # (mismo que Sign Up — agrega override login)
  ui/
    bloc/
      login_bloc.dart             # eventos + estados + BLoC en UN archivo
    screens/
      login_screen.dart
```

> `auth_repo.dart`, `auth_data_source.dart` y `auth_repo_impl.dart` son compartidos entre Sign Up y Login. Los UseCases son archivos separados.

### Contratos

**`lib/features/auth/domain/usecases/login_usecase.dart`**
```dart
class LoginUsecase {
  AuthRepo repo = AuthRepoImpl();

  Future<void> execute(String email, String password) async {
    await repo.login(email, password);
  }
}
```

### BLoC — `lib/features/auth/ui/bloc/login_bloc.dart`

```dart
// Events
abstract class LoginEvent {}

class LoginSubmitEvent extends LoginEvent {
  final String email;
  final String password;
  LoginSubmitEvent({required this.email, required this.password});
}

// States
abstract class LoginState {}
class LoginInitialState extends LoginState {}
class LoginLoadingState extends LoginState {}
class LoginSuccessState extends LoginState {}
class LoginFailState extends LoginState {
  final String message;
  LoginFailState(this.message);
}

// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginUsecase loginUsecase = LoginUsecase();

  LoginBloc() : super(LoginInitialState()) {
    on<LoginSubmitEvent>((event, emit) async {
      emit(LoginLoadingState());
      try {
        await loginUsecase.execute(event.email, event.password);
        emit(LoginSuccessState());
      } catch (e) {
        emit(LoginFailState(_mapError(e.toString())));
      }
    });
  }

  String _mapError(String error) {
    if (error.contains('invalid_credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (error.contains('network') || error.contains('socket')) {
      return 'No estás conectado a internet';
    }
    return 'Error: $error';
  }
}
```

### Acceptance Criteria

- [x] `login_usecase.dart` — archivo propio, un único método `execute`. Sin imports de Flutter ni Supabase.
- [x] `login_bloc.dart` — eventos, estados y BLoC en **un solo archivo**.
- [x] Estados: `Initial → Loading → Success / Fail`.
- [x] `LoginScreen` — `GlobalKey<FormState>` valida antes de disparar el evento.
- [x] `LoginScreen` — `BlocListener` navega a `/home` en `LoginSuccessState`.
- [x] `LoginScreen` — `BlocListener` muestra `SnackBar` en `LoginFailState`.
- [x] `LoginScreen` — `BlocBuilder` muestra `CircularProgressIndicator` en `LoginLoadingState`.
- [x] Campo email — `autovalidateMode: AutovalidateMode.onUserInteraction`. Mensaje: `'Falta el @'`.
- [x] Botón con toggle show/hide contraseña.
- [x] Link "¿No tienes cuenta? Regístrate" navega a `/signup`.
- [x] Ruta `/login` con `BlocProvider<LoginBloc>` en `main.dart`. Es la ruta inicial.

---

## Manifest de Implementación

| Feature | Capa | Archivo | Estado |
| :--- | :--- | :--- | :---: |
| **Shared — Auth** | Domain | `features/auth/domain/repo/auth_repo.dart` | ✅ |
| | Data | `features/auth/data/sources/auth_data_source.dart` | ✅ |
| | Data | `features/auth/data/repo/auth_repo_impl.dart` | ✅ |
| **Shared — Profile** | Domain | `features/profile/domain/model/profile.dart` | ✅ |
| | Domain | `features/profile/domain/repo/profile_repository.dart` | ✅ |
| | Data | `features/profile/data/sources/profile_data_source.dart` | ✅ |
| | Data | `features/profile/data/repo/profile_repository_impl.dart` | ✅ |
| **Sign Up** | Domain | `features/auth/domain/usecases/signup_usecase.dart` | ✅ |
| | UI | `features/auth/ui/bloc/signup_bloc.dart` | ✅ |
| | UI | `features/auth/ui/screens/signup_screen.dart` | ✅ |
| | Routing | `main.dart` — ruta `/signup` | ✅ |
| **Login** | Domain | `features/auth/domain/usecases/login_usecase.dart` | ✅ |
| | UI | `features/auth/ui/bloc/login_bloc.dart` | ✅ |
| | UI | `features/auth/ui/screens/login_screen.dart` | ✅ |
| | Routing | `main.dart` — ruta `/login` (inicial) | ✅ |

---
*Última actualización: 3 de Mayo, 2026*
