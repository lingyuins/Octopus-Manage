# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

Octopus Manager is a Flutter management client for [Octopus](https://github.com/lingyuins/octopus), an LLM API gateway and proxy. It provides a mobile/web UI for administering an Octopus server — managing channels, groups, API keys, viewing dashboards/logs, and configuring settings.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run the app (debug)
flutter test                 # Run tests
flutter analyze              # Lint / static analysis
flutter build apk --release  # Build Android APK
flutter build web --release  # Build web
```

No individual test file runner — `flutter test` runs all tests in `test/`. Tests cover model `toJson`/`fromJson` round-trips only (no widget or integration tests).

## Architecture

**Single-provider state management**: `AppProvider` (in `lib/providers/`) is the sole `ChangeNotifier`. It manages auth, locale, bootstrap status, and error state. Pages access it via `context.watch<AppProvider>()` and call the API through `provider.api`.

**Two-layer API service**:
- `ApiService` (`lib/services/api_service.dart`) — raw HTTP primitives with Bearer token auth, 15s timeout, automatic 401 logout
- `OctopusApi` (`lib/services/octopus_api.dart`) — typed wrapper over ApiService, mapping all `/api/v1/` endpoints to model objects

**App shell flow** (`main.dart`): loading → bootstrap (if fresh server) → login → `HomePage`

**Navigation**: `CupertinoTabScaffold` with 6 tabs (Dashboard, Channels, Groups, API Keys, Logs, Settings). No router — tab-based navigation only.

## Key Conventions

- **Cupertino-first UI**: `CupertinoApp` root, `CupertinoTabScaffold` navigation, `CupertinoAlertDialog` for dialogs. Material is used only for `ColorScheme.fromSeed()` and `SliverAppBar`.
- **Custom widgets** are prefixed with `App` (e.g., `AppCard`, `AppConfirmDialog`, `AppListTile`). Dialogs use static `show()` methods.
- **Design tokens** in `lib/theme/app_theme.dart`: centralized spacing (`spacingXs=4` through `spacingXxl=28`), radius (`radiusSmall=8` through `radiusXXLarge=28`), surface color hierarchy, and `Responsive` breakpoint class.
- **Color scheme seed**: `Color(0xFF007AFF)` (Apple blue).
- **Models** use manual `fromJson`/`toJson` (no code-gen). JSON keys are `snake_case` matching the Octopus API. `fromJson` uses `as Type? ?? defaultValue` for null safety.
- **i18n** is hand-rolled (`lib/l10n/app_localizations.dart`): `AppLocalizations.t(key)` with `_strings` map of key → `{AppLocale.en: ..., AppLocale.zh: ...}`. Not using Flutter's `gen_l10n`.
- **Persistence**: `SharedPreferences` stores base URL, auth token, locale, and wait time unit.

## CI/CD

Triggered on `v*` tag push (`.github/workflows/release.yml`):
1. Extracts version from tag, updates `pubspec.yaml`
2. Builds Android APK (release, with keystore from secrets)
3. Builds web (release)
4. Creates GitHub Release with both artifacts

Required secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`
