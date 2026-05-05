# Hookra Project Instructions

Hookra is a mobile SaaS platform designed for marketing agencies to centralize and automate social media content workflows, featuring AI-assisted generation, team collaboration, and performance analytics.

## Project Overview

This is a monorepo containing two main applications:
1.  **Mobile App (`hookra/`)**: Built with Flutter, following a specific Clean Architecture pattern.
2.  **Web App (`web/`)**: Built with Next.js (Vinext), featuring the landing page and dashboard.
3.  **Backend**: Powered by Supabase (Auth, Database, Storage).

---

## 📱 Mobile App (`hookra/`)

### Architecture & Conventions
The project is currently transitioning to a **Strict Clean Architecture**.

- **Legacy/Existing Code**: Located in `lib/src/`. Uses `get_it`, `go_router`, `freezed`, and `formz`.
- **New Features**: Located in `lib/features/`. **MUST** follow the rules in `specs_clean_arch.md`:
    - **Forbidden**: `get_it`, `freezed`, `formz`, `go_router`.
    - **Pattern**: `UI → BLoC → UseCase → RepoInterface → RepoImpl → DataSource → Supabase`.
    - **BLoC**: Events, States, and BLoC class must reside in a **single file** within the feature's `ui/bloc/` directory.
    - **Data Sources**: Only DataSources are allowed to import `supabase_flutter`.
    - **Domain**: Domain models and repository interfaces must be pure Dart (no external dependencies).

### Key Commands
- **Run**: `flutter run`
- **Test**: `flutter test`
- **Code Gen**: `dart run build_runner build --delete-conflicting-outputs` (Only for `lib/src/` legacy code)
- **Lint**: `flutter analyze`

---

## 🌐 Web App (`web/`)

### Architecture & Conventions
- **Framework**: Next.js 15+ (Vinext) with App Router.
- **UI**: Tailwind CSS 4, Radix UI, Shadcn.
- **State/Data**: React 19 features (Server Components, Suspense), Supabase SSR.
- **Linting/Formatting**: Uses `oxlint` and `oxfmt` for high-performance linting and formatting.

### Key Commands
- **Dev**: `npm run dev`
- **Build**: `npm run build`
- **Lint**: `npm run lint` (runs `oxlint --fix`)
- **Format**: `npm run fmt` (runs `oxfmt`)

---

## 🎨 Design System

**Aesthetic**: Premium SaaS (Linear/Stripe inspired).
- **Primary Color**: `#70020f` (Deep Red)
- **Background**: `#fafafa`
- **Surfaces**: White
- **Styling**: Minimalist, generous whitespace, soft rounded corners, typography-driven hierarchy.

---

## 🛠️ Development Guidelines

1.  **Supabase First**: Always check existing Supabase schemas before creating new models.
2.  **Feature Isolation**: When working in `lib/features/`, keep everything self-contained within the feature folder.
3.  **Clean Arch Compliance**: For any new mobile features, refer strictly to `hookra/specs_clean_arch.md`.
4.  **No Hidden Logic**: Avoid reflection or prototype manipulation. Use explicit composition and delegation.
5.  **Documentation**: Keep `specs_clean_arch.md` and `docs/PRODUCT.md` updated as the project evolves.
