
# Octopus Manager

English|[简体中文](README_zh.md)

A Flutter-based management client for [Octopus](https://github.com/lingyuins/octopus) — an LLM API gateway and proxy manager.

## Features

- **Dashboard** — Real-time today/total metrics, combined daily requests and cost chart, channel/API key rankings, and optional 15/30/60 second auto-refresh
- **Channel Management** — Add, edit, enable/disable, sync upstream channels, fetch available models, and test channel connectivity before saving
- **Group Management** — Configure routing groups with round-robin, random, failover, weighted, and auto modes; auto-group discovered models; test group health; and generate AI routes
- **Model Management** — Create, edit, and delete model pricing entries, inspect linked channels, and trigger upstream price sync
- **API Key Management** — Create, edit, enable/disable, and delete API keys with cost limits and expiration support
- **Relay Logs** — Paginated log browsing with pull-to-refresh and clear-all actions
- **Settings & Operations** — Change account credentials, export/import settings, tune retry/circuit-breaker/auto-strategy options, sync channels, update model prices, and trigger core updates
- **Bootstrap** — Initial admin account setup when connecting to a fresh Octopus server
- **i18n** — English and Chinese interface

## Prerequisites

- Flutter 3.x SDK
- Dart SDK `^3.10.4`
- A running [Octopus](https://github.com/lingyuins/octopus) server

## Getting Started

```bash
# Clone the repository
git clone https://github.com/lingyuins/Octopus-Manage.git
cd Octopus-Manage

# Install dependencies
flutter pub get

# Optional checks
flutter analyze
flutter test

# Run the app
flutter run
```

## Usage

1. Enter your Octopus server URL (e.g. `http://192.168.1.1:8080`)
2. If the server has no admin account yet, you'll be guided through the initial setup
3. Log in with your admin credentials
4. Enable "Remember me" for a long-lived session, or leave it unchecked for a short-lived login
5. Manage dashboards, channels, groups, models, API keys, logs, and server settings from the tab bar

## Architecture

Core runtime notes:

- `AppProvider` is the single `ChangeNotifier`, handling auth state, locale, bootstrap status, wait-time formatting, dashboard auto-refresh preferences, and global error state.
- `ApiService` provides raw HTTP primitives with Bearer auth, a 15 second timeout, persisted base URL/token, and automatic logout on `401`.
- `OctopusApi` is the typed API layer for auth, stats, channels, groups, models, API keys, logs, settings, and update endpoints.
- `main.dart` boots into a loading shell, then shows `HomePage` when a token exists or `LoginPage` otherwise; bootstrap is checked from the login flow and routes to `BootstrapPage` when needed.

```
lib/
├── l10n/           # Internationalization
├── models/         # Data models
├── pages/          # UI pages
│   ├── bootstrap_page.dart
│   ├── login_page.dart
│   ├── home_page.dart
│   ├── dashboard_page.dart
│   ├── channel_page.dart
│   ├── group_page.dart
│   ├── model_page.dart
│   ├── api_key_page.dart
│   ├── log_page.dart
│   └── setting_page.dart
├── providers/      # State management (Provider)
├── services/       # API service layer
│   ├── api_service.dart
│   └── octopus_api.dart
├── theme/          # Design tokens and responsive helpers
├── utils/          # Shared parsing helpers
├── widgets/        # Reusable widgets
└── main.dart
```

## Testing

- `flutter test` currently runs the suite in [test/widget_test.dart](/F:/codecil/octopusmanage/test/widget_test.dart)
- Existing tests focus on model serialization and null-safety behavior for core data models
- There are no widget or integration tests yet

## License

This project is licensed under the same license as Octopus.
