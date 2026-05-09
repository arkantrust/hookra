# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Project

Hookra — Flutter mobile app (Android/iOS only; no web/desktop targets in `pubspec.yaml`). Currently scaffolding (`version: 0.0.1`). Backend: Supabase (auth + Postgres `profiles` table).

## Commands

```sh
flutter pub get                                              # install deps
dart run build_runner build --delete-conflicting-outputs     # regen freezed/json_serializable (.freezed.dart / .g.dart)
dart run build_runner watch --delete-conflicting-outputs     # codegen on change
flutter analyze                                              # lint (flutter_lints + bloc_lint)
dart format .                                                # format
flutter test                                                 # all tests
flutter test test/models/email_test.dart                     # single file
flutter test --plain-name "rejects empty email"              # single test by name
flutter run                                                  # run app (requires .env)
flutter pub run flutter_native_splash:create                 # regen splash from flutter_native_splash.yaml
flutter pub run flutter_launcher_icons                       # regen launcher icons
```

App needs `.env` at project root with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (see `.env.example`). `.env` is loaded as a Flutter asset (declared in `pubspec.yaml`).

## Architecture

Clean architecture, feature-sliced under `lib/src/<feature>/`. Each feature has `domain/`, `data/`, `ui/` subfolders and a barrel file (e.g. `auth/auth.dart`) that re-exports the public surface. Import features through the barrel — internal paths are not the public API.

Layer rules:
- `domain/` — pure Dart. Repos are `abstract base class`. Use cases are tiny `call()` wrappers around a single repo method. Failures are plain `Exception` subclasses (`auth_failure.dart`, `user_failure.dart`). Value objects use `formz` (`Email`, `Password`, `Name`).
- `data/` — concrete repos (e.g. `SupabaseAuthRepository`) implement the domain interface, catch SDK-specific exceptions, and map them to domain failures wrapped in `Result<T>`.
- `ui/` — `views/` (pages), `blocs/<name>_bloc/` (split into `_bloc.dart`, `_event.dart`, `_state.dart` with `part`/`part of`), `mappers/` (e.g. validation-error → user-facing string).

Cross-cutting:
- `lib/src/app/` — `App` widget, `MaterialApp.router`, `AppRouter` (go_router), theme, `MainLayout`.
- `lib/src/config/` — `service_locator.dart` (GetIt singleton `sl`), Supabase client init.
- `lib/src/utils/` — `Result<T>` (Go-style success/failure wrapper used everywhere repos return), `network.dart`.
- `lib/src/components/` — shared themed widgets (form fields, buttons).

### Result<T>

`lib/src/utils/result.dart`. All repository/use-case async ops return `Future<Result<T>>` (or `Result<void>` via `Result.voidResult()`). Construct with `Result.success(v)`, `Result.failure(Exception)`, or `Result.unknown(name:, error:, stackTrace:)` for unmapped errors. Consume via `isSuccess` / `value` / `error` or `fold(onSuccess, onFailure)`. **Do not throw** across layer boundaries — wrap in `Result.failure`.

### Auth + routing

`AuthBloc` is a singleton in `GetIt`; subscribes to `WatchAuthStatusUseCase()` stream on `AuthSubscriptionRequested`. `AppRouter` uses `AuthRefreshStream(auth)` (a `ChangeNotifier` that fires on `AuthBloc.stream`) as `refreshListenable` and redirects between `/auth/*` and the shell routes (`/`, `/profile`) based on `auth.state.status`.

### DI

`initServiceLocator()` in `lib/src/config/service_locator.dart` is the only registration site. Repos and `AuthBloc` are singletons; use cases and feature blocs (`SignInBloc`, `SignUpBloc`) are factories. `App` wires repos via `MultiRepositoryProvider` and `AuthBloc` via `MultiBlocProvider`; everything else is resolved through `sl<T>()`.

### Codegen

`User` (`lib/src/profile/domain/entities/user.dart`) uses `freezed` + `json_serializable` with `fieldRename: FieldRename.snake` and `explicitToJson: true`. After editing any `@freezed` / `@JsonSerializable` class, run `dart run build_runner build --delete-conflicting-outputs`.

## Conventions

- Lint: `flutter_lints` + `prefer_single_quotes: true`; `invalid_annotation_target` ignored (for freezed).
- Tests live under `test/models/` and `test/utils/` mirroring source layout. Prefer `package:test`/`flutter_test` matchers; `package:checks` is encouraged but not yet adopted.
- Logging: `dart:developer` `log()`. `Bloc.observer = AppBlocObserver()` logs all bloc errors in `main.dart`.
- BLoC files split into `_bloc.dart` / `_event.dart` / `_state.dart` via `part` directives.
- Repos expose a `dispose()` and are disposed by `RepositoryProvider` in `App`.

## Notes

- `email.dart` validation is intentionally minimal (TODO in source). Don't tighten without coordinating with `test/models/email_test.dart`.
- `SupabaseAuthRepository.signIn` distinguishes `EmailNotFound` vs `WrongPassword` by querying the `profiles` table after an `invalid_credentials` error — keep this behavior if changing the data layer.
