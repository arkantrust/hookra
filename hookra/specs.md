# Specifications Manifest (specs.md)

Este documento define las especificaciones técnicas y funcionales para los features de **Sign In** y **Sign Up** de `hookra`. Sigue los principios de **Spec-Driven Development (SDD)** para asegurar que cada funcionalidad esté bien definida antes y durante su implementación.

> **Nota de arquitectura:** Este proyecto usa una arquitectura más avanzada que el guía base:
> - **DI:** `get_it` (ServiceLocator) en lugar de instanciación directa en UseCases.
> - **Routing:** `go_router` con guardas de redirección, en lugar de `Navigator.pushNamed`.
> - **Validación de formularios:** `formz` con `FormzInput` tipados (`Email`, `Password`, `Name`).
> - **Manejo de errores:** Tipo `Result<T>` en lugar de excepciones puras.
> - **Modelos:** `freezed` para generación de código (`User`).
> - **BLoC:** Archivos separados (`_bloc.dart`, `_event.dart`, `_state.dart`) en lugar de un único archivo.
> - **Estado global de auth:** `AuthenticationBloc` (singleton vía `get_it`) escucha el stream de `AuthenticationRepository`.

---

## 1. Feature: Sign Up (Registro)

### Objetivo
Permitir a nuevos usuarios crear una cuenta con nombre, apellido, correo electrónico y contraseña, integrándose con Supabase Auth y persistiendo el perfil en la tabla `profiles`.

### User Stories
- **Como** nuevo usuario, **quiero** registrarme con mi nombre, apellido, email y contraseña **para** poder acceder a las funcionalidades protegidas de la app.
- **Como** nuevo usuario, **quiero** que mi contraseña sea validada con reglas claras **para** saber si es suficientemente segura.
- **Como** nuevo usuario, **quiero** confirmar mi contraseña antes de registrarme **para** evitar errores de tipeo.

### Requerimientos Funcionales

- **Entradas:**
  | Campo | Tipo | Validación |
  |---|---|---|
  | Nombre (`firstName`) | `Name` (formz) | No vacío |
  | Apellido (`lastName`) | `Name` (formz) | No vacío |
  | Email (`email`) | `Email` (formz) | Formato `local@domain` |
  | Contraseña (`password`) | `Password` (formz) | ≥12 chars, número, mayúscula, minúscula, sin espacios |
  | Confirmar contraseña (`confirm`) | `Password` (formz) | Igual a `password` |

- **Acciones:**
  1. Validar cada campo en tiempo real via formz (estado `dirty`).
  2. Habilitar botón "Registrarme" solo cuando `SignUpState.isValid == true`.
  3. Disparar `SignUpSubmitted` → `SignUpBloc` llama a `AuthenticationRepository.signUp(...)`.
  4. Emitir `FormzSubmissionStatus.inProgress` durante la llamada.
  5. En éxito: emitir `FormzSubmissionStatus.success`; el `AuthenticationBloc` detecta el cambio en el stream y emite `AuthenticationState.authenticated(user)`.
  6. El `GoRouter` redirige automáticamente a `/home` cuando el estado global pasa a `authenticated`.
  7. En fallo: emitir `FormzSubmissionStatus.failure` con mensaje localizado en español.

- **Errores manejados:**

  | Excepción | Mensaje al usuario |
  |---|---|
  | `WeakPassword` | `'La contraseña es muy débil'` |
  | `EmailAlreadyExists` | `'Este correo ya está registrado'` |
  | `NoInternetConnection` | `'No estás conectado a internet'` |
  | `ServerUnreachable` | `'No fue posible acceder al servidor'` |
  | Desconocido | `'Algo salió mal'` |

- **Salida en éxito:** Redirección a `/home` vía redirección automática del router.
- **Salida en error:** `SnackBar` con el mensaje de error + `HapticFeedback.mediumImpact()`.

### Estructura de archivos

```
lib/src/authentication/
  repository/
    authentication_repository.dart          # Interfaz abstracta (signUp, signIn, signOut, status)
    supabase_authentication_repository.dart  # Implementación real con Supabase
    fake_authentication_repository.dart      # Implementación fake para tests
    authentication_failure.dart              # Excepciones tipadas
  blocs/
    sign_up_bloc/
      sign_up_bloc.dart    # Lógica + handlers
      sign_up_event.dart   # SignUpFirstChanged, SignUpLastChanged, SignUpEmailChanged,
                           # SignUpPasswordChanged, SignUpConfirmChanged, SignUpSubmitted
      sign_up_state.dart   # SignUpState (formz status, campos, isValid, error)
  views/
    sign_up_page.dart      # UI con BlocProvider, BlocListener, BlocBuilder

lib/src/models/
  email.dart     # FormzInput<String, EmailValidationError>
  password.dart  # FormzInput<String, PasswordValidationError>
  name.dart      # FormzInput<String, NameValidationError>
  user.dart      # Modelo User (freezed)

lib/src/config/
  service_locator.dart  # registerFactory<SignUpBloc>
```

### Acceptance Criteria

- [x] `SignUpPage` con campos: Nombre, Apellido, Email, Contraseña, Confirmar contraseña.
- [x] `SignUpBloc` maneja eventos de cambio por campo y `SignUpSubmitted`.
- [x] `SignUpState.isValid` usa `Formz.validate([first, last, email, password, confirm]) && password.value == confirm.value`.
- [x] Botón "Registrarme" deshabilitado (`onPressed: null`) cuando `isValid == false`.
- [x] `CircularProgressIndicator` (via `ThemedTextButton.isInProgressOrSuccess`) durante `inProgress`.
- [x] `BlocListener` muestra `SnackBar` con mensaje localizado en fallo.
- [x] `HapticFeedback.mediumImpact()` en fallo.
- [x] Navegación a `SignInPage` desde `SignUpPage` (link "Ya tienes una cuenta?").
- [x] `SupabaseAuthenticationRepository.signUp` distingue `WeakPassword` y `EmailAlreadyExists`.
- [x] `SupabaseAuthenticationRepository.signUp` maneja `AuthRetryableFetchException` consultando conectividad.
- [x] `SignUpBloc` registrado como `registerFactory` en `service_locator.dart`.
- [ ] **BUG:** El `onPressed` del botón navega a `/home` inmediatamente junto al dispatch del evento, sin esperar `FormzSubmissionStatus.success`. La navegación debe moverse al `BlocListener` condicionado a `state.status.isSuccess`.
- [ ] Validación de email robusta (actualmente solo verifica `@` y partes no vacías; marcado como TODO en `email.dart`).
- [ ] Validación de símbolo especial en contraseña (actualmente comentada en `password.dart`).
- [ ] Almacenamiento seguro del token de sesión con `flutter_secure_storage` (actualmente usa `SharedPreferences`).

---

## 2. Feature: Sign In (Login)

### Objetivo
Permitir a usuarios existentes iniciar sesión con su email y contraseña, restaurando su sesión activa y redirigiendo al flujo principal de la app.

### User Stories
- **Como** usuario registrado, **quiero** iniciar sesión con mi email y contraseña **para** retomar mi actividad en la app.
- **Como** usuario, **quiero** recibir mensajes claros **para** saber si el error es en mi email o en mi contraseña.
- **Como** usuario nuevo, **quiero** poder ir a la pantalla de registro desde el login **para** crear mi cuenta.

### Requerimientos Funcionales

- **Entradas:**
  | Campo | Tipo | Validación |
  |---|---|---|
  | Email (`email`) | `Email` (formz) | Formato `local@domain` |
  | Contraseña (`password`) | `Password` (formz) | ≥12 chars, número, mayúscula, minúscula, sin espacios |

- **Acciones:**
  1. Validar campos en tiempo real via formz (estado `dirty`).
  2. Habilitar botón "Iniciar sesión" solo cuando `SignInState.isValid == true`.
  3. Disparar `SignInSubmitted` → `SignInBloc` llama a `AuthenticationRepository.signIn(...)`.
  4. Emitir `FormzSubmissionStatus.inProgress` durante la llamada.
  5. En éxito: emitir `FormzSubmissionStatus.success`; el `AuthenticationBloc` detecta el `signedIn` en el stream y emite `AuthenticationState.authenticated(user)`.
  6. El `GoRouter` redirige automáticamente a `/home` cuando el estado global pasa a `authenticated`.
  7. En fallo: emitir `FormzSubmissionStatus.failure` con mensaje localizado en español.

- **Errores manejados:**

  | Excepción | Mensaje al usuario |
  |---|---|
  | `WrongPassword` | `'Contraseña incorrecta'` |
  | `EmailNotFound` | `'No estás registrado'` |
  | `NoSessionFound` | `'Algo salió mal'` (fallback) |
  | `NoInternetConnection` | `'No estás conectado a internet'` |
  | `ServerUnreachable` | `'No fue posible acceder al servidor'` |
  | Desconocido | `'Algo salió mal'` |

  > **Nota:** Para distinguir `WrongPassword` vs `EmailNotFound`, el repo consulta la tabla `profiles` buscando el email. Si no existe → `EmailNotFound`; si existe → `WrongPassword`.

- **Salida en éxito:** Redirección a `/home` vía redirección automática del router.
- **Salida en error:** `SnackBar` con el mensaje de error + `HapticFeedback.mediumImpact()`.

### Estructura de archivos

```
lib/src/authentication/
  repository/
    authentication_repository.dart          # Interfaz abstracta
    supabase_authentication_repository.dart  # signIn con distinción WrongPassword/EmailNotFound
    authentication_failure.dart              # EmailNotFound, WrongPassword, NoSessionFound, ...
  blocs/
    sign_in_bloc/
      sign_in_bloc.dart    # Lógica + handlers
      sign_in_event.dart   # SignInEmailChanged, SignInPasswordChanged, SignInSubmitted
      sign_in_state.dart   # SignInState (formz status, email, password, isValid, error)
  views/
    sign_in_page.dart      # UI con BlocProvider, BlocListener, BlocBuilder

lib/src/config/
  service_locator.dart  # registerFactory<SignInBloc>
```

### Acceptance Criteria

- [x] `SignInPage` con campos: Email y Contraseña.
- [x] `SignInBloc` maneja `SignInEmailChanged`, `SignInPasswordChanged`, `SignInSubmitted`.
- [x] `SignInState.isValid` usa `Formz.validate([email, password])`.
- [x] Botón "Iniciar sesión" deshabilitado (`onPressed: null`) cuando `isValid == false`.
- [x] `CircularProgressIndicator` (via `ThemedTextButton.isInProgressOrSuccess`) durante `inProgress`.
- [x] `BlocListener` muestra `SnackBar` con mensaje localizado en fallo.
- [x] `HapticFeedback.mediumImpact()` en fallo.
- [x] Navegación a `SignUpPage` desde `SignInPage` (link "No tienes una cuenta aún?").
- [x] `SupabaseAuthenticationRepository.signIn` distingue `WrongPassword` vs `EmailNotFound` consultando `profiles`.
- [x] `SupabaseAuthenticationRepository.signIn` verifica que `session != null` antes de confirmar éxito.
- [x] `SupabaseAuthenticationRepository.signIn` maneja `AuthRetryableFetchException` consultando conectividad.
- [x] `SignInBloc` registrado como `registerFactory` en `service_locator.dart`.
- [ ] **BUG:** El `onPressed` del botón navega a `/home` inmediatamente junto al dispatch del evento, sin esperar `FormzSubmissionStatus.success`. La navegación debe moverse al `BlocListener` condicionado a `state.status.isSuccess`.
- [ ] Pantalla / flujo de "Olvidaste tu contraseña?" (marcado como TODO en `sign_in_page.dart`).
- [ ] Validación de email robusta (mismo TODO que en Sign Up).

---

## 3. Feature: AuthenticationBloc (Estado global de sesión)

### Objetivo
Mantener el estado global de autenticación y coordinar la redirección automática del router según si el usuario está autenticado o no.

### Requerimientos Funcionales
- Escuchar el `Stream<AuthenticationStatus>` de `AuthenticationRepository`.
- En `authenticated`: obtener el `User` desde `UserRepository` y emitir `AuthenticationState.authenticated(user)`.
- En `unauthenticated`: emitir `AuthenticationState.unauthenticated()`.
- En sign out: limpiar caché de `UserRepository`.
- El `GoRouter` usa un `AuthenticationRefreshStream` que escucha el stream del `AuthenticationBloc` para disparar re-evaluaciones del redirect.

### Acceptance Criteria
- [x] `AuthenticationBloc` registrado como `registerSingleton` en `service_locator.dart`.
- [x] `AuthenticationSubscriptionRequested` disparado en `app.dart` al iniciar.
- [x] `AuthenticationSignOutPressed` limpia el caché con `userRepository.dispose()`.
- [x] `GoRouter.redirect` redirige a `/auth/sign-in` si `!isAuthenticated && !goingToAuth`.
- [x] `GoRouter.redirect` redirige a `/splash` mientras `status == unknown`.
- [x] `AuthenticationRefreshStream` notifica al router en cada cambio de estado del BLoC.
- [ ] Manejo del error cuando `UserRepository.getUser()` falla tras autenticación exitosa (actualmente emite `unauthenticated`, pero no notifica al usuario).

---

## Manifest de Implementación

| Feature | Sub-tarea | Estado | Notas |
| :--- | :--- | :---: | :--- |
| **Sign Up** | UI (`SignUpPage`) | ✅ | Campos: nombre, apellido, email, contraseña, confirmación. |
| | `SignUpBloc` (eventos + estados) | ✅ | 5 eventos de cambio + `SignUpSubmitted`. |
| | Validación de formulario (formz) | ✅ | `Name`, `Email`, `Password` + match de contraseñas. |
| | Integración Supabase (`SupabaseAuthenticationRepository.signUp`) | ✅ | Distingue `WeakPassword` y `EmailAlreadyExists`. |
| | Manejo de errores de red | ✅ | `NoInternetConnection` y `ServerUnreachable`. |
| | Mensajes de error localizados (español) | ✅ | Todos los casos cubiertos en el BLoC. |
| | Navegación correcta en éxito (vía `BlocListener`) | ❌ | BUG: navega antes de confirmar éxito. |
| | Validación robusta de email | ❌ | TODO en `email.dart`. |
| | Validación de símbolo en contraseña | ❌ | Comentada en `password.dart`. |
| | Token seguro (`flutter_secure_storage`) | ❌ | TODO en `supabase.dart`. |
| **Sign In** | UI (`SignInPage`) | ✅ | Campos: email y contraseña. |
| | `SignInBloc` (eventos + estados) | ✅ | 2 eventos de cambio + `SignInSubmitted`. |
| | Validación de formulario (formz) | ✅ | `Email` y `Password`. |
| | Integración Supabase (`SupabaseAuthenticationRepository.signIn`) | ✅ | Distingue `WrongPassword` vs `EmailNotFound`. |
| | Manejo de errores de red | ✅ | `NoInternetConnection` y `ServerUnreachable`. |
| | Mensajes de error localizados (español) | ✅ | Todos los casos cubiertos en el BLoC. |
| | Navegación correcta en éxito (vía `BlocListener`) | ❌ | BUG: navega antes de confirmar éxito. |
| | "Olvidaste tu contraseña?" | ❌ | TODO en `sign_in_page.dart`. |
| **AuthBloc** | Stream de estado global | ✅ | Detecta `signedIn`, `tokenRefreshed`, `signedOut`. |
| | Redirección con `GoRouter` | ✅ | Guards en `router.dart` para autenticado/no-autenticado. |
| | `UserRepository` cache en sign out | ✅ | `dispose()` limpia el caché. |
| | Error handling en `getUser()` post-auth | ❌ | Emite `unauthenticated` silenciosamente sin feedback. |

---
*Última actualización: 3 de Mayo, 2026*
