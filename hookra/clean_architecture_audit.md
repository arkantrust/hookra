# Hookra — Clean Architecture Audit Report

**Date:** 2026-05-17  
**Auditor:** Principal Architecture Review  
**Scope:** Full repository audit — all layers, all features  
**Branch:** `dev`

---

## 1. Executive Summary

### Overall Architectural Health Score: **5.2 / 10**

The codebase is a tale of two codebases. The `auth` and `profile` features are textbook-quality Clean Architecture: proper layer separation, Result<T> wrapping, typed domain failures, value objects, and BLoC-driven state. The `organizations` feature — the app's core business capability — is architecturally broken: Supabase is called directly in UI, business logic lives in dialog callbacks, the repository interface throws raw exceptions instead of `Result<T>`, and there are no use cases for the vast majority of operations.

Critically, there is also a latent **data-correctness bug** introduced by the architectural violation: when a user creates an organization in the UI dialog, they are being added as a `'member'` instead of `'owner'`. This is a direct consequence of having business logic in the presentation layer.

### Main Architectural Risks

| Risk | Severity |
|---|---|
| Supabase SDK called directly in UI widgets | Critical |
| Business logic in dialog callbacks (including a role bug) | Critical |
| OrganizationRepository does not use `Result<T>` | Critical |
| `Result<T>.isSuccess` is semantically broken for void results | High |
| Auth domain depends on Organizations domain (cross-feature coupling) | High |
| Missing use cases for 7 of 8 organization operations | High |
| BLoC directly holds `OrganizationRepository` (bypasses use case layer) | High |
| `OrganizationDetailsPage` not registered in go_router (no deep-link) | High |
| Dead DI registration (`registerFactoryParam` for OrganizationMembersBloc) | Medium |
| `MemberWithProfile` DTO defined inside domain repo interface file | Medium |
| Domain entities carry `fromJson`/`toJson` directly | Medium |
| Domain role string `'owner'` passed as raw `String` (type-safety breach) | Medium |

### Technical Debt Estimate

- **Immediate defects:** 2 (broken navigation route `/login`, role bug `'member'` vs `'owner'`)
- **High-effort refactors:** ~40–60 hours (organizations feature full re-arch)
- **Medium-effort cleanups:** ~15–20 hours (Result<T> fix, failure types, DTO extraction)
- **Low-effort wins:** ~5–8 hours (DI cleanup, navigation, type fixes)

### Scalability Assessment

The architecture is **not scalable in its current form.** Adding a second major feature (content, analytics, approvals) following the `organizations` pattern would produce an unmaintainable codebase within 3–4 sprints. Following the `auth` pattern, it would scale well. The project urgently needs a feature architecture contract enforced via code review before the next feature is built.

---

## 2. Repository Architecture Overview

### Intended Architecture

Feature-sliced Clean Architecture under `lib/src/<feature>/`:
- **Domain:** pure Dart — `abstract base class` repos, thin use cases, typed failures, value objects
- **Data:** concrete Supabase repos implementing domain interfaces, wrapping all operations in `Result<T>`
- **UI:** `StatelessWidget` views, BLoC for state, mappers for error translation

### Actual Architecture

| Feature | Intended | Actual | Alignment |
|---|---|---|---|
| `auth` | Clean Arch | Clean Arch | ✅ High |
| `profile` | Clean Arch | Clean Arch (minor gaps) | ✅ High |
| `organizations` | Clean Arch | Procedural with BLoC veneer | ❌ Low |
| `home` | Clean Arch | Empty shell / alias | ⚠️ N/A |
| `utils` | Cross-cutting | Correct but has domain classes | ⚠️ Partial |

The codebase's architecture quality regresses progressively from `auth` (earliest, most refined) to `organizations` (latest, most rushed). This is a classic sign of **schedule-driven architectural erosion.**

---

## 3. Violations by Layer

---

### 3.1 Presentation Layer Violations

---

#### V-P01 — Infrastructure (Supabase) called directly in UI: sign-out

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:47`

```dart
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await Supabase.instance.client.auth.signOut(); // ❌ direct Supabase call
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // ❌ broken route
    }
  },
),
```

**Why it violates:** The presentation layer directly imports and calls `supabase_flutter`. This violates the Dependency Rule: outer layers can depend on inner layers, but never the reverse, and the outer layer must never reach through abstractions to call concrete infrastructure. `SignOutUseCase` already exists for exactly this purpose. `AuthBloc.add(AuthSignOutPressed())` already handles this flow end-to-end.

**Architectural impact:** Any future change to the auth provider (e.g., swapping Supabase for Firebase) requires hunting UI files. The auth event stream (`AuthBloc`) no longer controls the sign-out lifecycle — it's bypassed entirely, meaning `AuthBloc` state can desynchronize from actual auth state.

**Compound bug:** The route `/login` does not exist. The actual route is `/auth/sign-in`. This navigation will silently fail at runtime (go_router will hit the `errorBuilder`). The page then sits in a broken state because `AuthBloc` never heard about the sign-out (since the direct Supabase call doesn't trigger the `_controller.stream` in `SupabaseAuthRepository`).

Wait — actually `supabase_flutter` fires `onAuthStateChange` which `SupabaseAuthRepository.status` listens to, so AuthBloc would eventually get the event. But the imperative navigation still races with the redirect.

**Severity:** Critical  
**Fix:** Replace with `context.read<AuthBloc>().add(AuthSignOutPressed())`. Remove the `Navigator` call — `AppRouter`'s `redirect` handles navigation automatically when `AuthBloc` emits `unauthenticated`.  
**Refactor complexity:** Trivial (5 min)

---

#### V-P02 — Infrastructure (Supabase) called in UI to get current user

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:166`

```dart
ElevatedButton(
  onPressed: () async {
    final user = Supabase.instance.client.auth.currentUser; // ❌
    if (user != null) {
      final organization = await _repository.createOrganization(
        nameController.text.trim(),
        user.id,
      );
```

**File:** `lib/src/organizations/ui/pages/organization_details_page.dart:72`

```dart
Widget build(BuildContext context) {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id; // ❌ on every rebuild
```

**Why it violates:** The current user's identity is already available in `AuthBloc.state.user.id`. The `AuthBloc` is a singleton in the widget tree. Calling `Supabase.instance.client.auth.currentUser` in the UI layer is a triple violation: it bypasses the domain model (`User` entity), bypasses the state management layer (`AuthBloc`), and couples the widget to Supabase directly. The call in `build()` re-evaluates on every widget rebuild, which is inefficient.

**Severity:** Critical  
**Fix:** `context.read<AuthBloc>().state.user.id` for one-time access; `context.select((AuthBloc b) => b.state.user.id)` for reactive binding.  
**Refactor complexity:** Trivial (10 min)

---

#### V-P03 — Repository accessed directly in UI (bypasses use case layer entirely)

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:25`

```dart
class _OrganizationsPageState extends State<OrganizationsPage> {
  final OrganizationRepository _repository = sl<OrganizationRepository>(); // ❌
  late Future<List<OrganizationWithRole>> _organizationsFuture;
```

**Why it violates:** In Clean Architecture, the presentation layer communicates with the application layer (use cases/BLoCs) and never skips directly to the domain's repository abstractions. The state widget holds a repository reference and calls it imperatively in `initState`, turning a `StatefulWidget` into an ad-hoc ViewModel without the testability or predictability of a proper BLoC.

**Architectural impact:** This widget cannot be unit-tested without instantiating Supabase. The repository call has no loading/error state management beyond a manual `FutureBuilder`. Retry logic (`setState(() => _loadOrganizations())`) resets UI state manually, making state transitions unpredictable.

**Severity:** Critical  
**Fix:** Create `GetOrganizationsUseCase`, create `OrganizationsBloc` with `LoadOrganizations` event. Convert `OrganizationsPage` to `StatelessWidget`.  
**Refactor complexity:** Medium (4–6 hours)

---

#### V-P04 — Business logic executed inside a UI dialog callback

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:160-196`

```dart
ElevatedButton(
  onPressed: () async {
    if (nameController.text.trim().isEmpty) return; // validation in UI

    try {
      final user = Supabase.instance.client.auth.currentUser; // infrastructure in UI
      if (user != null) {
        final organization = await _repository.createOrganization(
          nameController.text.trim(),
          user.id,
        );
        await _repository.addMember(     // ❌ business flow in dialog
          organization.id,
          user.id,
          'member',                       // ❌ BUG: should be 'owner'
        );
```

**Why it violates:** The dialog callback is orchestrating a multi-step business transaction: validate → get user identity → create organization → add member. This is an application-layer concern (use case) being executed in a UI callback with no error recovery, no atomicity, and a **semantic bug**: the creator is added as `'member'` not `'owner'`. Compare with `SignUpWithOrganizationUseCase.call()` at line 47 which correctly uses `'owner'`. The UI duplicated the logic and got it wrong.

**This is the clearest evidence of why business logic belongs in use cases, not UI:** a correct implementation already exists (`SignUpWithOrganizationUseCase`), but the developer duplicated the flow in the dialog and introduced a silent role corruption bug.

**Severity:** Critical (includes data correctness bug)  
**Fix:** Create `CreateOrganizationUseCase` that orchestrates both `createOrganization` and `addMember(role: OrganizationRole.owner)`. Emit a BLoC event from the UI. Delete the dialog's business logic.  
**Refactor complexity:** Medium (2–3 hours)

---

#### V-P05 — Repository called directly in UI for name update (bypasses BLoC)

**File:** `lib/src/organizations/ui/pages/organization_details_page.dart:44-68`

```dart
Future<void> _saveName() async {
  if (_nameController.text.trim().isEmpty) return;

  final repository = sl<OrganizationRepository>(); // ❌ fresh sl<> call inside a method
  try {
    await repository.updateOrganizationName(      // ❌ direct repo call from UI
      widget.organizationId,
      _nameController.text.trim(),
    );
    _bloc.add(LoadMembers(widget.organizationId)); // ❌ manual state sync
```

**Why it violates:** A new repository instance is obtained from the service locator inside a method — this is a runtime DI anti-pattern (called "Service Locator inside logic"). The state is then manually re-synchronized by firing a `LoadMembers` event, which re-fetches all data just to reflect a name change. There is no `UpdateOrganizationNameUseCase`, no BLoC event for name updates, and no `UpdateOrganizationName` event in `OrganizationMembersEvent`.

**Severity:** High  
**Fix:** Add `UpdateOrganizationName` event to the BLoC. Create `UpdateOrganizationNameUseCase`. Handle optimistic update in BLoC.  
**Refactor complexity:** Low-Medium (2 hours)

---

#### V-P06 — BLoC manually instantiated in StatefulWidget (bypasses DI)

**File:** `lib/src/organizations/ui/pages/organization_details_page.dart:28-34`

```dart
@override
void initState() {
  super.initState();
  _bloc = OrganizationMembersBloc(      // ❌ manual construction
    repository: sl<OrganizationRepository>(),
    updateMemberRoleUseCase: sl(),
  );
  _bloc.add(LoadMembers(widget.organizationId));
}
```

**Why it violates:** The DI container has already registered this bloc:

```dart
// service_locator.dart:59-63
sl.registerFactoryParam<OrganizationMembersBloc, String, void>(
  (organizationId, _) => OrganizationMembersBloc(
    repository: sl<OrganizationRepository>(),
    updateMemberRoleUseCase: sl<UpdateMemberRoleUseCase>(),
  ),
);
```

This registration is **dead code** — it is never called. The page re-implements construction manually and ignores the `organizationId` parameter the DI factory was designed to receive. If construction logic ever changes in the service locator, this page will drift silently.

**Severity:** Medium  
**Fix:** Use `BlocProvider(create: (_) => sl.call<OrganizationMembersBloc, String>(widget.organizationId))` and convert the widget to `StatelessWidget`.  
**Refactor complexity:** Low (1 hour)

---

#### V-P07 — Imperative navigation mixed with declarative go_router

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:234-241`

```dart
onTap: () {
  Navigator.push(       // ❌ imperative navigator
    context,
    MaterialPageRoute(
      builder: (_) => OrganizationDetailsPage(
        organizationId: organization.id,
      ),
    ),
  );
},
```

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:49`

```dart
Navigator.pushReplacementNamed(context, '/login'); // ❌ broken route + wrong paradigm
```

**Why it violates:** The project uses go_router as its single routing authority. `OrganizationDetailsPage` has no `static GoRoute route()` method and is not registered in `AppRouter`. It is only reachable through this imperative push. Consequences: (1) deep linking is impossible, (2) auth-based redirects do not apply to this screen, (3) the back-button and URL state are inconsistent with go_router's history.

**Severity:** High  
**Fix:** Add `GoRoute(path: '/organizations/:id', ...)` to `AppRouter`. Implement `static GoRoute route()` on `OrganizationDetailsPage`. Replace `Navigator.push` with `context.push('/organizations/${organization.id}')`.  
**Refactor complexity:** Low (1 hour)

---

#### V-P08 — `_OrganizationCard` uses `dynamic` typed fields

**File:** `lib/src/organizations/ui/pages/organizations_page.dart:203-207`

```dart
class _OrganizationCard extends StatelessWidget {
  final dynamic organization; // ❌ erases type safety
  final dynamic role;         // ❌
```

**Why it violates:** `dynamic` fully opts out of Dart's type system. Any field access on `organization.name`, `organization.id` is resolved at runtime, removing compile-time safety. The surrounding code correctly has `Organization` and `OrganizationRole` types available.

**Severity:** Medium  
**Fix:** `final Organization organization; final OrganizationRole role;`  
**Refactor complexity:** Trivial (5 min)

---

#### V-P09 — Sign-up navigation fires before async operation completes

**File:** `lib/src/auth/ui/views/sign_up_page.dart:190-195`

```dart
onPressed: context.select((SignUpBloc bloc) => bloc.state.isValid)
    ? () {
        context.read<SignUpBloc>().add(const SignUpSubmitted());
        context.go(HomePage.route().path); // ❌ navigates immediately
      }
    : null,
```

**Why it violates:** `SignUpSubmitted` triggers an async operation (`SignUpWithOrganizationUseCase.call()`), which can fail. The navigation to `HomePage` fires synchronously before the result is known. If the sign-up fails (e.g., email already exists), the `BlocListener` catches the failure and shows a snackbar — but the user has already been navigated away. The `AppRouter`'s auth-redirect handles the success case, but this imperative `context.go` races with it.

**Severity:** Medium  
**Fix:** Remove the imperative `context.go` call. The `AppRouter.redirect` will navigate to `HomePage` automatically when `AuthBloc` emits `AuthStatus.authenticated` after successful sign-up.  
**Refactor complexity:** Trivial (2 min)

---

#### V-P10 — `HomePage` is an alias that creates a hidden cross-feature dependency

**File:** `lib/src/home/ui/views/home_page.dart`

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const OrganizationsPage(); // ❌ home depends on organizations implementation
  }
}
```

And in `AppRouter`:
```dart
HomePage.route(),       // route: /
OrganizationsPage.route(), // route: /organizations
```

**Why it violates:** `OrganizationsPage` is rendered at two routes (`/` and `/organizations`) by different means. `home` imports from `organizations`. When `home` grows its own content (dashboard, analytics), this coupling will require surgery. The route duplication also means `OrganizationsPage` has two mount points with different contexts.

**Severity:** Low  
**Fix:** `HomePage` should have its own content. Move the organizations navigation to a tab or card within home.  
**Refactor complexity:** Medium (when home feature is implemented)

---

### 3.2 Application Layer Violations

---

#### V-A01 — `OrganizationMembersBloc` directly depends on `OrganizationRepository`

**File:** `lib/src/organizations/ui/blocs/organization_members_bloc/organization_members_bloc.dart:13-14`

```dart
class OrganizationMembersBloc extends Bloc<OrganizationMembersEvent, OrganizationMembersState> {
  final OrganizationRepository _repository;      // ❌ BLoC holds repo directly
  final UpdateMemberRoleUseCase _updateMemberRoleUseCase;
```

```dart
Future<void> _onLoadMembers(LoadMembers event, ...) async {
  final organization = await _repository.getOrganizationById(event.organizationId); // ❌
  final members = await _repository.getOrganizationMembers(event.organizationId);   // ❌
```

**Why it violates:** The BLoC is the application layer. It should only depend on use cases, which are the orchestration unit of the application layer. Direct repository access in a BLoC collapses two layers: the BLoC simultaneously acts as orchestrator (application) and data-fetcher (skipping use cases). There are no use cases for `GetOrganizationById` or `GetOrganizationMembers`.

**Contrast with auth:** `AuthBloc` only holds `WatchAuthStatusUseCase`, `SignOutUseCase`, `GetUserUseCase`. It never holds a repository.

**Severity:** High  
**Fix:** Create `GetOrganizationDetailsUseCase` (returns org + members), inject into BLoC instead of repository.  
**Refactor complexity:** Medium (3 hours)

---

#### V-A02 — Missing use cases for 7 of 8 organization operations

The `OrganizationRepository` interface declares 8 methods. Use cases exist for **1**:

| Repository Method | Use Case Exists? |
|---|---|
| `getOrganizationsForCurrentUser()` | ❌ Missing |
| `createOrganization()` | ❌ Missing |
| `addMember()` | ❌ Missing |
| `generateUniqueSlug()` | ❌ Missing |
| `getOrganizationById()` | ❌ Missing |
| `updateOrganizationName()` | ❌ Missing |
| `getOrganizationMembers()` | ❌ Missing |
| `updateMemberRole()` | ✅ `UpdateMemberRoleUseCase` |

**Why it violates:** Use cases are the application layer's boundary. Without them, business orchestration migrates to wherever the repo is called — in this case, UI widgets and BLoCs. The single existing use case (`UpdateMemberRoleUseCase`) demonstrates the team knows the pattern but did not apply it consistently.

**Severity:** High  
**Fix:** Create one use case per business operation. Combine `getOrganizationById` + `getOrganizationMembers` into `GetOrganizationDetailsUseCase` for the details screen's single fetch.  
**Refactor complexity:** Medium (4–6 hours for all)

---

#### V-A03 — `SignUpWithOrganizationUseCase` creates cross-feature domain dependency

**File:** `lib/src/auth/domain/use_cases/sign_up_with_organization_use_case.dart:3`

```dart
import 'package:hookra/src/organizations/organizations.dart'; // ❌ auth domain → org domain
```

**Why it violates:** The `auth` domain layer imports from the `organizations` feature barrel. In a modular architecture, `auth` must be self-contained. The dependency graph now has `auth.domain → organizations.domain`, meaning the organizations feature cannot be refactored without potentially breaking auth. The two features are tightly coupled at their deepest layer.

**Long-term risk:** If organizations is ever extracted to a separate package (micro-frontend), this coupling propagates. If auth is tested in isolation, it requires organizations to be instantiated.

**Severity:** High  
**Fix:** Move `SignUpWithOrganizationUseCase` to a separate coordination layer (e.g., `lib/src/onboarding/` or `lib/src/app/use_cases/`) that is allowed to import both features. Or define an `OrganizationCreationPort` interface in auth that organizations implements (Dependency Inversion at the feature boundary).  
**Refactor complexity:** Medium (2 hours)

---

#### V-A04 — `addMember()` accepts `String role` instead of `OrganizationRole`

**File:** `lib/src/organizations/domain/repo/organization_repository.dart:24`

```dart
Future<void> addMember(String organizationId, String profileId, String role); // ❌ String
```

**File:** `lib/src/organizations/data/repo/supabase_organization_repository.dart:88-89`

```dart
// Should receive OrganizationRole   ← the developer knew this
Future<void> addMember(String organizationId, String profileId, String role) async {
```

**Why it violates:** The domain layer defines its own `OrganizationRole` enum precisely to avoid stringly-typed role passing. The interface accepts `String`, bypassing type safety. Callers pass `'owner'`, `'member'`, `'admin'` as raw strings, and any typo silently inserts the wrong role. The comment in the data layer acknowledges this is wrong but was left unfixed.

**Severity:** Medium  
**Fix:** `Future<void> addMember(String organizationId, String profileId, OrganizationRole role);`  
**Refactor complexity:** Trivial (15 min)

---

### 3.3 Domain Layer Violations

---

#### V-D01 — `OrganizationRepository` does not return `Result<T>`

**File:** `lib/src/organizations/domain/repo/organization_repository.dart:22-34`

```dart
abstract class OrganizationRepository {
  Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser(); // ❌ throws
  Future<Organization> createOrganization(String name, String ownerId); // ❌ throws
  Future<void> addMember(String organizationId, String profileId, String role); // ❌ throws
  Future<String> generateUniqueSlug(String baseName); // ❌ throws
  Future<Organization?> getOrganizationById(String organizationId); // ❌ throws
  Future<void> updateOrganizationName(String organizationId, String name); // ❌ throws
  Future<List<MemberWithProfile>> getOrganizationMembers(String organizationId); // ❌ throws
  Future<void> updateMemberRole(String organizationId, String profileId, OrganizationRole); // ❌ throws
}
```

**Compare with `AuthRepository`:**

```dart
abstract base class AuthRepository {
  Future<Result<void>> signUp({...});   // ✅
  Future<Result<void>> signIn({...});   // ✅
  Future<Result<void>> signOut();       // ✅
}
```

**Why it violates:** The `Result<T>` contract is the project's defined error-handling strategy (per `AGENTS.md`). `OrganizationRepository` is the only repository that breaks this contract. Every caller must now use try/catch instead of `fold`/`isFailure`. The `UpdateMemberRoleUseCase` wraps the call in try/catch specifically to compensate for this — but `_onLoadMembers` in the BLoC also uses try/catch, meaning two different error-handling mechanisms exist in the same feature. The data layer's `getOrganizationsForCurrentUser` even throws a raw `Exception('Failed to get current user')` — a completely unmapped, untypeable error.

**Severity:** Critical  
**Fix:** Change all return types to `Future<Result<T>>`. Implement failure types (`OrganizationNotFound`, `UnauthorizedOrgAccess`, `OrgAlreadyExists`). Remove all try/catch compensation in callers.  
**Refactor complexity:** Medium (3–4 hours)

---

#### V-D02 — Domain entities carry `fromJson`/`toJson` serialization

**File:** `lib/src/organizations/domain/model/organization.dart:18-38`

```dart
class Organization extends Equatable {
  factory Organization.fromJson(Map<String, dynamic> json) { // ❌ serialization in domain
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerId: json['owner_id'] as String, // ❌ DB column name leaked into domain
      ...
    );
  }

  Map<String, dynamic> toJson() { // ❌ persistence concern in domain entity
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'owner_id': ownerId,
      ...
    };
  }
}
```

**Why it violates:** Domain entities should be pure business objects with no knowledge of how they are persisted or serialized. The `owner_id` key in `fromJson` leaks the Supabase database column naming convention directly into the domain layer. If the column is renamed in the DB, the domain entity must change. The same pattern exists in `OrganizationMember.fromJson/toJson`.

**Note:** The `User` entity (profile feature) uses `@freezed` + `@JsonSerializable(fieldRename: FieldRename.snake)` — the same problem exists (annotations + generated code in the domain entity) but it is more idiomatic and isolates the mapping. The organizations entities are worse because the mapping is fully manual and the DB column name is a magic string in domain code.

**Severity:** Medium  
**Fix:** Move `fromJson`/`toJson` to dedicated DTO classes in `data/models/`. Have the data layer map DTO → domain entity. Domain entities hold no serialization code.  
**Refactor complexity:** Medium (2–3 hours)

---

#### V-D03 — `MemberWithProfile` DTO defined inside the domain repo interface file

**File:** `lib/src/organizations/domain/repo/organization_repository.dart:5-19`

```dart
class MemberWithProfile {      // ❌ a DTO disguised as a domain type
  final String profileId;
  final String firstName;
  final String lastName;
  final String email;
  final OrganizationRole role;
  ...
}
```

**Why it violates:** `MemberWithProfile` is a database projection — the result of a JOIN between `organization_members` and `profiles`. It is not a domain entity with identity or business behaviour; it is a read model / DTO for displaying member lists. Placing it in the domain repository interface file means the domain is modeling the persistence query shape, not the business concept. In a true domain model, you'd have an `OrganizationMember` entity (which exists) and resolve the `Profile` separately or via a dedicated read model.

**Severity:** Medium  
**Fix:** Extract to `data/models/member_with_profile_dto.dart`. Create a `MemberView` read model in domain if needed, or return `(OrganizationMember, User)` tuples from the repository.  
**Refactor complexity:** Medium (1–2 hours)

---

#### V-D04 — `generateUniqueSlug()` is an infrastructure concern in the domain interface

**File:** `lib/src/organizations/domain/repo/organization_repository.dart:25`

```dart
Future<String> generateUniqueSlug(String baseName); // ❌ infrastructure in domain interface
```

**File:** `lib/src/organizations/data/repo/supabase_organization_repository.dart:113-127`

```dart
// TODO: Make sure slugs are unique
// This function should only normalize the name, not ensure uniqueness.
// Uniqueness should be handled with atomicity in the DB
@override
Future<String> generateUniqueSlug(String baseName) async {
  return baseName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .trim();
}
```

**Why it violates:** Slug generation requires knowledge of what slugs already exist in the database. It's a persistence-level uniqueness concern, not a domain concept. Its presence on the domain repo interface forces all implementations to support this infrastructure-specific operation. The TODO comment acknowledges the implementation is broken (doesn't actually check uniqueness) — a consequence of misplacing the responsibility.

**Severity:** Medium  
**Fix:** Remove from the interface. Move slug normalization to a private utility in the data layer. Implement uniqueness via a Supabase unique constraint + retry logic in the data layer only.  
**Refactor complexity:** Low-Medium (1–2 hours)

---

#### V-D05 — Duplicate role-parsing logic: domain vs. data layer

**File:** `lib/src/organizations/domain/model/organization_member.dart:24-32`  
**File:** `lib/src/organizations/data/repo/supabase_organization_repository.dart:18-27`

```dart
// In domain entity:
static OrganizationRole _parseRole(String? role) { ... }

// In data repository:
static OrganizationRole _parseMemberRole(String? role) { ... }
```

Both methods are functionally identical. The domain entity parses DB string values — a data-layer concern — and the repository duplicates the parsing for its own queries.

**Why it violates:** Role parsing from string is a serialization concern belonging exclusively in the data layer. A domain entity should only be constructed with already-typed values.

**Severity:** Low  
**Fix:** Remove `_parseRole` from `OrganizationMember`. Consolidate in data layer. Use `OrganizationRole` directly when constructing domain objects.  
**Refactor complexity:** Trivial (20 min)

---

#### V-D06 — No failure types for the `organizations` feature

`auth` has `auth_failure.dart` with 5 typed exceptions. `profile` has `user_failure.dart`. `organizations` has no failure types at all. All errors bubble as raw `Exception` or `e.toString()`. The `OrganizationMembersBloc` stores `state.errorMessage` as a raw string, making programmatic error handling in the UI impossible.

**Severity:** Medium  
**Fix:** Create `lib/src/organizations/domain/failures/organization_failure.dart` with: `OrgNotFound`, `UnauthorizedOrgAccess`, `OrgAlreadyExists`, `MemberAlreadyExists`, `OwnerCannotBeRemoved`.  
**Refactor complexity:** Low (1 hour)

---

#### V-D07 — Organizations domain folder named `model/` instead of `entities/`

`profile/domain/entities/` vs `organizations/domain/model/` — structural inconsistency. Minor but violates the documented convention.

**Severity:** Low  
**Fix:** Rename `domain/model/` → `domain/entities/`. Update all imports.  
**Refactor complexity:** Trivial (10 min with IDE refactoring)

---

### 3.4 Data Layer Violations

---

#### V-Da01 — Data layer catches `Result.isFailure` then re-throws as `Exception`

**File:** `lib/src/organizations/data/repo/supabase_organization_repository.dart:41-45`

```dart
Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser() async {
  final user = await _userRepository.getUser(); // returns Result<User>
  if (user.isFailure) {
    throw Exception('Failed to get current user'); // ❌ unwraps Result then re-throws
  }
```

**Why it violates:** `UserRepository.getUser()` returns `Result<User>` precisely to avoid exceptions crossing layer boundaries. The data layer unwraps the `Result`, discards the typed failure (`UserNotFound`, `NoInternetConnection`, etc.), and re-throws a generic `Exception`. The original failure context is lost. This is the worst of both worlds: uses `Result` but throws anyway.

**Fix:** Return `Result.failure(user.error)` (propagate) or map to an organization-specific failure.  
**Severity:** High  
**Refactor complexity:** Trivial (2 min)

---

#### V-Da02 — `createOrganization` uses `.single()` (acknowledged as wrong in a TODO)

**File:** `lib/src/organizations/data/repo/supabase_organization_repository.dart:80-84`

```dart
final response =
    await _supabase
        .from('organizations')
        .insert({'name': name, 'slug': slug, 'owner_id': ownerId})
        .select()
        .single(); // TODO: Use maybeSingle
```

`.single()` throws if zero or multiple rows are returned. The TODO acknowledges it should be `.maybeSingle()`, but `.maybeSingle()` returns `null` on no rows — the real fix is to handle both cases explicitly.

**Severity:** Low  
**Refactor complexity:** Trivial (5 min)

---

#### V-Da03 — `SupabaseOrganizationRepository` registered as singleton but has no `dispose()`

**File:** `lib/src/config/service_locator.dart:17-22`

```dart
sl.registerSingleton<OrganizationRepository>(
  SupabaseOrganizationRepository(
    supabase: supabase,
    userRepository: sl<UserRepository>(),
  ),
);
```

`AuthRepository` and `UserRepository` both define `dispose()` (abstract in their interfaces). `OrganizationRepository` has no `dispose()` method and is not added to `App`'s `MultiRepositoryProvider` (only `AuthRepository` and `UserRepository` are). Its lifecycle is unmanaged.

**Severity:** Low  
**Fix:** Add `Future<void> dispose()` to `OrganizationRepository` interface. Add to `MultiRepositoryProvider` in `app.dart`.  
**Refactor complexity:** Low (30 min)

---

### 3.5 Cross-Cutting Violations

---

#### V-C01 — `Result<T>.isSuccess` is semantically incorrect for void results

**File:** `lib/src/utils/result.dart:46-48`

```dart
bool get isSuccess => _value != null && _error == null;
```

`Result.voidResult()` stores `_value = null`. Therefore `isSuccess` returns `false` for all void results. The `fold()` method compounds this:

```dart
U fold<U>(U Function(T?) onSuccess, U Function(Exception) onFailure) {
  if (isSuccess) {           // false for voidResult
    return onSuccess(_value);
  }
  return onFailure(_error!); // _error is null → null check throws at runtime!
}
```

Calling `.fold()` on a `Result<void>` success will throw a `Null check operator used on a null value` runtime exception. The project avoids this by always using `isFailure` instead of `fold`, but any future developer using `fold` or `isSuccess` on a void result will hit a confusing runtime error.

**Severity:** High (latent correctness bug with incorrect API contract)  
**Fix:**
```dart
// Add a discriminant field:
enum _ResultKind { success, failure, void_ }
// Or: track void separately
bool _isVoid;

// Simplest fix:
bool get isSuccess => _error == null; // success OR void, both are "not failed"
bool get isVoid => _error == null && _value == null;
```

Or redesign to `Result<void>` where `void` is a unit type so `_value` is never null for success.  
**Refactor complexity:** Low-Medium (affects all callers of `isSuccess`)

---

#### V-C02 — `NoInternetConnection` and `ServerUnreachable` defined in `utils/network.dart`

**File:** `lib/src/utils/network.dart:17-22`

```dart
class NoInternetConnection implements Exception {
  const NoInternetConnection();
}

class ServerUnreachable implements Exception {
  const ServerUnreachable();
}
```

These are domain-level failure types that semantically belong to a shared failures file (e.g., `lib/src/utils/failures.dart` or `lib/src/shared/domain/failures/network_failure.dart`). Their current location in `network.dart` (an infrastructure utility file) means importing domain failure types also imports the `hasInternetAccess()` network probe — an unrelated infrastructure concern.

**Severity:** Low  
**Fix:** Move to `lib/src/shared/domain/failures/network_failure.dart`.  
**Refactor complexity:** Trivial (15 min)

---

## 4. Feature-by-Feature Audit

---

### 4.1 `auth` Feature

**Architecture Quality Score: 8.5 / 10**

| Dimension | Assessment |
|---|---|
| Layer separation | ✅ Excellent — clean domain/data/ui boundaries |
| Use cases | ✅ Present for all auth operations |
| Failure modeling | ✅ Typed failures in `auth_failure.dart` |
| Value objects | ✅ `Email`, `Password`, `Name` via `formz` |
| Repository interface | ✅ `abstract base class`, `Result<T>` for all methods |
| State management | ✅ Proper `AuthBloc` + `SignInBloc` + `SignUpBloc` |
| Error mapping | ✅ `field_error_mappers.dart` |
| Testability | ✅ All dependencies are injectable abstractions |

**Issues:**
- V-P09: `context.go` fires before async sign-up completes (Medium)
- V-A03: `SignUpWithOrganizationUseCase` creates cross-feature dependency (High)
- `auth_failure.dart` missing `NoInternetConnection`/`ServerUnreachable` (they're in `network.dart`) (Low)
- `AuthRepository.dispose()` is `void` not `Future<void>` — inconsistent with `UserRepository` (Low)

**Coupling:** Low internal. Moderate external (imports from `organizations` feature).  
**Testability:** High — all deps are injected abstractions.  
**Scalability:** High — pattern is correct and extensible.

---

### 4.2 `profile` Feature

**Architecture Quality Score: 7.0 / 10**

| Dimension | Assessment |
|---|---|
| Layer separation | ✅ Correct structure |
| Use cases | ✅ `GetUserUseCase` |
| Failure modeling | ⚠️ Partial — `UserNotFound` exists, but `NoInternetConnection`/`ServerUnreachable` used without being in `user_failure.dart` |
| Repository interface | ✅ `Result<T>` |
| State management | ⚠️ `ProfilePage` reads directly from `AuthBloc` (not a dedicated `ProfileBloc`) |
| Testability | ✅ Good |

**Issues:**
- `ProfilePage` reads `AuthBloc.state.user` — acceptable for read-only display but creates coupling between profile UI and auth state. If user profile becomes editable, this will need a `ProfileBloc`. (Low-Medium)
- `SupabaseUserRepository` has in-memory `_user` cache that's cleared by `dispose()` called from `AuthBloc._onSignOutPressed` — this works but the cache invalidation logic is hidden and fragile. (Low)
- The `user_failure.dart` is very sparse — only `UserNotFound`. Profile-specific failures (stale cache, profile update failure) are not modeled.

**Coupling:** Low.  
**Testability:** High.  
**Scalability:** Medium — will need `ProfileBloc` when profile editing is added.

---

### 4.3 `organizations` Feature

**Architecture Quality Score: 2.5 / 10**

| Dimension | Assessment |
|---|---|
| Layer separation | ❌ UI calls infrastructure, UI executes business logic |
| Use cases | ❌ 1 of 8 operations covered |
| Failure modeling | ❌ No failure types |
| Repository interface | ❌ No `Result<T>` |
| State management | ⚠️ `OrganizationMembersBloc` exists but holds repo directly; `OrganizationsPage` uses `FutureBuilder` + `setState` |
| Navigation | ❌ `OrganizationDetailsPage` not in go_router |
| Testability | ❌ Nearly untestable (Supabase imported in UI, BLoC depends on concrete repo) |

**Active bugs introduced by architectural violations:**
1. Organization creator added as `'member'` instead of `'owner'` (V-P04)
2. Sign-out navigates to `/login` which doesn't exist (V-P01)
3. `fold()` will crash on `Result<void>` success (V-C01)

**Coupling:** High — UI imports Supabase directly; auth domain imports organizations.  
**Testability:** Very Low — Supabase must be mocked at 3 call sites just to test the list screen.  
**Scalability:** Low — the current approach cannot be extended without amplifying the existing violations.

---

### 4.4 `home` Feature

**Architecture Quality Score: 1.0 / 10** (N/A — essentially non-existent)

`home_page.dart` renders `OrganizationsPage`. There is no home-specific domain, data, or logic. The feature folder is a shell that adds a dependency edge (`home → organizations`) without providing any value.

**Risk:** When the home screen gets real content (dashboard, analytics), this file will need a complete rewrite rather than incremental extension.

---

### 4.5 `utils` (Cross-cutting)

**Quality Score: 7.0 / 10**

`Result<T>` is a well-designed utility that is core to the project's error handling. The `fold()` / void result bug (V-C01) is the primary issue. `network.dart` mixing infrastructure (`hasInternetAccess`) with domain failure types (`NoInternetConnection`) is a secondary issue.

---

## 5. Dependency Graph Problems

```
Correct dependency direction: UI → Application → Domain ← Data

Actual violations:

UI (organizations_page) ─────────────────────────────► supabase_flutter (infra)
UI (organization_details_page) ──────────────────────► supabase_flutter (infra)
UI (organizations_page) ──────────────────────────────► OrganizationRepository (domain)
UI (organization_details_page) ──────────────────────► OrganizationRepository (domain)
auth.domain (sign_up_with_org_use_case) ─────────────► organizations.domain (cross-feature)
organizations.domain (organization.dart) ────────────► serialization format (json keys)
organizations.domain (organization_member.dart) ─────► serialization format (json keys)
organizations.domain (organization_repository.dart) ─► MemberWithProfile (should be DTO)
```

**Circular dependencies:** None found. The violation direction is consistently wrong (toward infrastructure) rather than circular.

**Import direction summary:**

| Import | Expected | Actual |
|---|---|---|
| `organizations_page` → `supabase_flutter` | ❌ Never | ✅ Exists |
| `organization_details_page` → `supabase_flutter` | ❌ Never | ✅ Exists |
| `auth.domain` → `organizations.domain` | ❌ Never | ✅ Exists |
| `organizations.domain.entity` → json schema | ❌ Never | ✅ Exists |

---

## 6. Architectural Consistency Report

### Features Following Correct Patterns
- `auth` — reference implementation
- `profile` — close second, minor gaps

### Features with Mixed Patterns
- None — the split is binary: auth/profile (good) vs. organizations (bad)

### Features that Bypass Architecture
- `organizations` — procedural code with a BLoC component bolted on
- `home` — empty shell

### Architectural Drift Pattern

The codebase shows clear evidence of **schedule-driven drift**:

1. `auth` was implemented first. It has the most refined architecture: value objects, typed failures, error mappers, full Result<T> coverage, BLoC factories in DI.
2. `profile` was implemented second. Slightly simpler (no dedicated ProfileBloc) but structurally correct.
3. `organizations` was implemented later (based on git history: PR #13 "feat: roles-management"). It shortcuts almost every pattern established by auth — likely developed under time pressure.

This pattern is dangerous because **later features have more business complexity** (organizations, roles, members) but **less architectural discipline**. The most complex domain is the least protected.

### Mixed DI Patterns

| Component | How Instantiated |
|---|---|
| `AuthBloc` | `sl<AuthBloc>()` via `BlocProvider` in `App` |
| `SignInBloc` | `sl<SignInBloc>()` via `BlocProvider` in `SignInPage` |
| `SignUpBloc` | `sl<SignUpBloc>()` via `BlocProvider` in `SignUpPage` |
| `OrganizationMembersBloc` | Manually `OrganizationMembersBloc(...)` in `initState()` |

Three different instantiation patterns for BLoCs in a single codebase.

---

## 7. Most Dangerous Problems (Ranked)

### Rank 1 — Data Correctness Bug: Organization Creator Added as `'member'` Not `'owner'`

**File:** `organizations_page.dart:173`  
**Impact:** Every organization created via the UI dialog has its creator as `member` instead of `owner`. This is a production data bug. The authorization logic (`RoleAuthorization.canChangeRole`) checks `organization.ownerId` against `currentUserId` — the DB row will have the correct `owner_id` from `createOrganization` insert, but `organization_members` will have `role = 'member'`. Any UI checks on `OrganizationRole.owner` will fail for self-created orgs.  
**Why caused by architecture:** Business logic in UI dialog, duplicated from `SignUpWithOrganizationUseCase` but incorrectly.

### Rank 2 — `Result<T>.fold()` Crashes on Void Success

**File:** `result.dart:84-89`  
**Impact:** Any future use of `.fold()` on a void Result (signOut, signUp, addMember, updateOrganizationName, updateMemberRole) throws a null-dereference at runtime with no warning at compile time. As the codebase grows and developers reach for the canonical `fold` API, this will produce hard-to-diagnose crashes.

### Rank 3 — Supabase Imported Directly in UI (Three Call Sites)

**Files:** `organizations_page.dart:47, 166`, `organization_details_page.dart:72`  
**Impact:** Untestable UI (can't mock `Supabase.instance`), broken sign-out flow (auth state desync possible), auth provider lock-in.

### Rank 4 — Broken Navigation Route `/login`

**File:** `organizations_page.dart:49`  
**Impact:** Sign-out flow navigates to a non-existent route. In go_router, this hits `errorBuilder`, displaying an error screen rather than the sign-in page. Users who sign out via this button are stranded.

### Rank 5 — `OrganizationRepository` Has No `Result<T>` Contract

**Impact:** Error information is lost (V-Da01), callers use inconsistent error handling (try/catch vs Result), typed failure handling is impossible. This is the root cause of multiple downstream violations.

### Rank 6 — `OrganizationDetailsPage` Not in go_router

**Impact:** No deep-linking, no auth redirect on this screen, broken navigation hierarchy, URL does not reflect current screen.

### Rank 7 — Auth Domain Depends on Organizations Domain

**Impact:** Features cannot evolve independently, `auth` cannot be tested without `organizations`, cross-feature refactors become entangled.

### Rank 8 — 7 Missing Use Cases for Organization Operations

**Impact:** Business logic migrates to UI and BLoC. The role bug (Rank 1) is a direct consequence. Without use cases, there is no single authoritative location for organizational business rules.

### Rank 9 — Dead DI Registration (`registerFactoryParam` for `OrganizationMembersBloc`)

**Impact:** Developers reading the service locator see a registration that is never exercised. The actual construction is manual and inconsistent. When the service locator registration is eventually used, the `organizationId` parameter is ignored.

### Rank 10 — Domain Entities Carry `fromJson`/`toJson`

**Impact:** DB schema changes (renaming columns) require touching domain entities. The domain layer is coupled to the persistence format. Serialization bugs become domain bugs.

---

## 8. Refactor Roadmap

### Quick Wins (< 1 day each)

| # | Fix | File(s) | Effort |
|---|---|---|---|
| QW1 | Fix role bug: `'member'` → `'owner'` in `_showCreateOrganizationDialog` | `organizations_page.dart:173` | 2 min |
| QW2 | Fix broken route: remove `Navigator.pushReplacementNamed(context, '/login')`, replace with `context.read<AuthBloc>().add(AuthSignOutPressed())` | `organizations_page.dart:46-51` | 5 min |
| QW3 | Remove `context.go(HomePage.route().path)` from sign-up button | `sign_up_page.dart:194` | 2 min |
| QW4 | Replace `dynamic` with `Organization`/`OrganizationRole` in `_OrganizationCard` | `organizations_page.dart:203-207` | 5 min |
| QW5 | Fix `addMember()` signature to use `OrganizationRole` instead of `String` | `organization_repository.dart:24` | 15 min |
| QW6 | Fix `Result<T>.isSuccess` for void results | `result.dart:46` | 20 min |
| QW7 | Move `NoInternetConnection`/`ServerUnreachable` to shared failures file | `network.dart:17-22` | 15 min |

### Medium-Term Refactors (1–2 weeks)

| # | Fix | Effort |
|---|---|---|
| MT1 | Add `Result<T>` to all `OrganizationRepository` methods + update implementation | 4h |
| MT2 | Create `organization_failure.dart` with typed exceptions | 1h |
| MT3 | Create missing use cases: `GetOrganizationsUseCase`, `CreateOrganizationUseCase`, `GetOrganizationDetailsUseCase`, `UpdateOrganizationNameUseCase`, `AddMemberUseCase` | 4h |
| MT4 | Create `OrganizationsBloc` (LoadOrganizations, CreateOrganization, RefreshOrganizations events) | 3h |
| MT5 | Convert `OrganizationsPage` to `StatelessWidget`, wire `OrganizationsBloc` | 3h |
| MT6 | Add `UpdateOrganizationName` event to `OrganizationMembersBloc`, remove direct repo call from `_saveName` | 2h |
| MT7 | Register `OrganizationDetailsPage` in go_router at `/organizations/:id` | 1h |
| MT8 | Remove `OrganizationRepository` dependency from `OrganizationMembersBloc`; use `GetOrganizationDetailsUseCase` | 2h |
| MT9 | Add `OrganizationRepository` to `MultiRepositoryProvider` in `app.dart`; add `dispose()` | 30min |
| MT10 | Extract `fromJson`/`toJson` from `Organization` and `OrganizationMember` into DTO classes in `data/` | 2h |
| MT11 | Move `MemberWithProfile` out of `organization_repository.dart` to `data/models/` | 1h |
| MT12 | Fix dead `registerFactoryParam` DI registration | 30min |

### High-Impact Architectural Improvements (Sprint-level)

| # | Fix | Rationale |
|---|---|---|
| HI1 | Move `SignUpWithOrganizationUseCase` to `app/` or `onboarding/` feature | Decouples auth and organizations at domain level |
| HI2 | Replace `generateUniqueSlug()` in domain interface with DB-level unique constraint + data-layer retry | Correct layer responsibility; fixes the acknowledged uniqueness bug |
| HI3 | Establish architecture linting: define import rules via `analysis_options.yaml` or `import_lint` package | Prevents future cross-layer imports without code review intervention |
| HI4 | Write unit tests for all use cases using mock repos | Forces proper dependency inversion; catches regressions |
| HI5 | Introduce `ProfileBloc` for profile feature ahead of editing functionality | Prevents the same architecture collapse that hit organizations |

### Suggested Execution Order

```
Week 1: QW1 → QW2 → QW3 → QW4 → QW5 → QW6 → QW7 (all quick wins, ship a fix build)
Week 2: MT1 → MT2 → MT3 (foundation: Result<T> + failures + use cases)
Week 3: MT4 → MT5 → MT8 (OrganizationsBloc + convert page)
Week 4: MT6 → MT7 → MT9 → MT10 → MT11 → MT12 (remaining cleanups)
Sprint 3+: HI1 → HI2 → HI3 → HI4 → HI5
```

---

## 9. Final Verdict

### Is this truly Clean Architecture?

**Partially.** Two of four features (`auth`, `profile`) implement Clean Architecture correctly and would pass a rigorous review. The `organizations` feature — the application's core domain — implements **none of the defined architectural contracts**: it has no use cases, no Result<T> repository, no typed failures, no proper state management, and directly invokes Supabase in its UI widgets. `home` does not exist as a real feature.

The architecture is best described as: **Clean Architecture with a procedural island.**

### Is it pseudo-clean architecture?

For the `organizations` feature: **yes.** It has the folder structure of Clean Architecture (`domain/`, `data/`, `ui/`, `blocs/`) but none of the behavioral contracts. The folders give an impression of discipline that the implementation does not honor. This is more dangerous than pure procedural code — it signals "Clean Architecture is applied here" while violations accumulate invisibly.

### Is the architecture sustainable?

**Not in its current trajectory.** The risk is clear: the most recently developed feature has the worst architecture. If this trend continues (auth was clean, organizations was not, the next feature will be worse), the codebase will become unmaintainable before reaching feature parity with the product vision. The team clearly understands Clean Architecture — the `auth` feature proves it — but is not applying it consistently under development pressure.

### What should be prioritized immediately?

**In order:**

1. **Fix the role bug** (`'member'` → `'owner'` in `organizations_page.dart:173`) — data correctness issue shipping to users now.
2. **Fix the broken sign-out navigation** (`/login` does not exist) — crashes user flow.
3. **Fix `Result<T>.isSuccess`** — latent runtime crash that will surface as the codebase grows.
4. **Add `Result<T>` to `OrganizationRepository`** — all other organizations refactors are blocked on this.
5. **Create the missing use cases** — without them, business logic will continue to land in UI.
6. **Create `OrganizationsBloc`** and convert `OrganizationsPage` to stateless — removes the last UI-held repository reference.
7. **Register `OrganizationDetailsPage` in go_router** — enables deep linking and auth redirects.

Items 1–3 can be done in under 30 minutes. Items 4–7 are a coherent refactor sprint. Everything else is incremental improvement.

The team has the knowledge to do this right — the `auth` feature is proof. The `organizations` feature needs to be brought up to that standard before building further on top of it.
