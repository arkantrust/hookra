You are now responsible for executing the refactor plan described in `clean_architecture_audit.md`.

Your task is NOT to do a superficial cleanup.
Your task is to systematically migrate the repository toward a consistent, production-grade Clean Architecture implementation while preserving functionality.

Before making changes:

1. Read the entire `clean_architecture_audit.md`
2. Understand every violation and its architectural reasoning
3. Use `AGENTS.md` as the architectural source of truth
4. Analyze the current repository implementation carefully before modifying anything

# Refactor Strategy

You MUST refactor incrementally and safely.

DO NOT attempt to refactor the entire repository in a single massive change.

Instead:

* work in small architectural batches
* keep the app compiling after every batch
* avoid introducing partial inconsistent states
* preserve existing behavior
* avoid unnecessary rewrites

For every refactor batch:

1. Explain what you are about to refactor
2. Explain WHY it matters architecturally
3. Implement the refactor
4. Update all affected imports/usages
5. Ensure no dead code remains
6. Ensure the project compiles
7. Ensure existing tests still pass
8. Generate a short refactor report

# Execution Order

Follow THIS exact order unless a dependency requires adjustment.

## Phase 1 — Critical Bugs & Quick Wins

Fix ONLY:

* Role bug (`member` -> `owner`)
* Broken `/login` navigation
* `Result<T>.isSuccess` void bug
* Premature navigation in sign up
* `dynamic` usages in organization cards
* `String role` -> `OrganizationRole`

Do not refactor anything else in this phase.

---

## Phase 2 — Organizations Error Handling Architecture

Refactor the entire `organizations` feature to use:

* `Result<T>`
* typed failures
* consistent failure mapping
* no raw exceptions crossing layers

Tasks:

* create `organization_failure.dart`
* update `OrganizationRepository`
* update repository implementation
* remove try/catch compensation code
* update callers

Keep the app compiling at all times.

---

## Phase 3 — Application Layer Restoration

Introduce missing use cases:

* GetOrganizationsUseCase
* CreateOrganizationUseCase
* GetOrganizationDetailsUseCase
* UpdateOrganizationNameUseCase
* AddMemberUseCase

Rules:

* business orchestration belongs ONLY in use cases
* UI cannot coordinate business flows
* BLoCs cannot directly orchestrate repository logic

---

## Phase 4 — Presentation Layer Cleanup

Refactor:

* OrganizationsPage
* OrganizationDetailsPage
* related BLoCs

Goals:

* remove direct repository usage from UI
* remove direct Supabase usage from UI
* remove business logic from widgets/dialogs
* introduce OrganizationsBloc
* ensure BLoCs depend only on use cases
* remove manual DI anti-patterns

---

## Phase 5 — Routing & Navigation

Refactor navigation to fully use go_router:

* register OrganizationDetailsPage
* remove imperative Navigator usage
* ensure auth redirects work correctly
* support deep linking

---

## Phase 6 — Domain Purification

Refactor:

* remove serialization from domain entities
* create DTOs/mappers
* remove persistence concerns from domain
* move MemberWithProfile out of domain repo file
* eliminate duplicated parsing logic

---

## Phase 7 — Cross-Feature Decoupling

Eliminate:

* auth.domain -> organizations.domain dependency

Introduce:

* proper coordination layer
  OR
* ports/interfaces for feature communication

---

# Important Constraints

You MUST:

* preserve existing behavior
* avoid breaking public APIs unnecessarily
* avoid introducing architectural overengineering
* follow existing coding style
* keep feature modularity
* keep dependency direction correct

You MUST NOT:

* introduce hacks
* silence problems
* bypass architecture to “make it work”
* leave TODOs instead of implementations
* create dead abstractions
* partially migrate patterns

# Refactor Quality Standard

The final architecture should resemble the quality level of the current `auth` feature, which should be treated as the reference implementation.

Every architectural decision must be justified according to:

* dependency inversion
* separation of concerns
* feature modularity
* testability
* scalability
* maintainability

# Deliverables Per Phase

For each phase:

1. Explain what was changed
2. List modified files
3. Explain architectural improvements
4. Mention risks/tradeoffs
5. Mention any remaining follow-up work

Do NOT skip phases.
Do NOT batch all phases together.
Complete one phase fully before moving to the next.
