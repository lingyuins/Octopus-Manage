# Octopus Manager

A Flutter-based management client for [Octopus](https://github.com/lingyuins/octopus) — an LLM API gateway and proxy manager.

## Features

- **Dashboard** — Real-time stats: requests, costs, tokens, success rate with daily charts
- **Channel Management** — Add, edit, enable/disable, and sync upstream LLM provider channels
- **Group Management** — Configure routing groups with round-robin, random, failover, and weighted modes
- **API Key Management** — Create, edit, and delete API keys with cost limits and expiration
- **Relay Logs** — Browse and clear request logs
- **Settings** — Configure server settings including CORS, proxy, circuit breaker, and more
- **Bootstrap** — Initial admin account setup when connecting to a fresh Octopus server
- **i18n** — English and Chinese interface

## Prerequisites

- Flutter 3.x SDK
- A running [Octopus](https://github.com/lingyuins/octopus) server

## Getting Started

```bash
# Clone the repository
git clone https://github.com/lingyuins/Octopus-Manage.git
cd Octopus-Manage

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Usage

1. Enter your Octopus server URL (e.g. `http://192.168.1.1:8080`)
2. If the server has no admin account yet, you'll be guided through the initial setup
3. Log in with your admin credentials
4. Enable "Remember me" for a 30-day session, or leave it unchecked for a 15-minute session

## Architecture

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
│   ├── api_key_page.dart
│   ├── log_page.dart
│   └── setting_page.dart
├── providers/      # State management (Provider)
├── services/       # API service layer
│   ├── api_service.dart
│   └── octopus_api.dart
├── widgets/        # Reusable widgets
└── main.dart
```

## License

This project is licensed under the same license as Octopus.
