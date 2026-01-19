# Smart Expense Tracker

Smart Expense Tracker is a cross-platform Flutter app that helps people log expenses and income, set budgets, and get AI-powered financial insights. It connects to Appwrite for auth, data storage, and notifications, and uses Google Gemini to generate personalized spending advice.

## Features

- Email/password auth with session handling via Appwrite
- Expense and income tracking with categories and recurring records
- Budgets per category with progress tracking and warnings
- Dashboard with charts (spending trends, category breakdowns, monthly totals)
- AI insights (analysis, advice, saving tips, warnings) powered by cached Appwrite data and Gemini
- In-app education feed for financial literacy
- Local notifications and badge updates for reminders and new insights
- Settings for profile, preferences, and data refresh

## Tech Stack

- Flutter (Dart 3.10) with Material 3 theming
- Appwrite (auth, databases, health check)
- Google Gemini via `google_generative_ai`
- `fl_chart` for visualizations
- `shared_preferences` and custom cache services
- `flutter_local_notifications` with timezone support

## Project Structure (high level)

- `lib/main.dart` – app bootstrap, routes, theme
- `lib/core/` – initialization (Appwrite client), theme, shared widgets, utils, services (notifications, cache, badges)
- `lib/features/` – domain features (`auth`, `expenses`, `budgets`, `dashboard`, `ai`, `education`, `settings`, etc.)
- `lib/services/` – shared services (auth, preload, AI, analytics helpers)
- `assets` – `.env` is loaded for secrets (see setup)
- `ARCHITECTURE_DIAGRAM.md`, `CLASS_DIAGRAM.puml` – reference docs/diagrams

## Prerequisites

- Flutter SDK 3.10.4+ and Dart 3.10+
- Android Studio or Xcode tooling for device builds
- Appwrite project (endpoint and project ID are currently set in `lib/core/init/appwrite_client.dart`)
- Google Gemini API key

## Setup

1. Install dependencies

```bash
flutter pub get
```

2. Create environment file

```bash
cp example.env .env
```

Fill `.env` with your values:

```
GEMINI_API_KEY=your_key_here
```

3. Configure Appwrite (if different from defaults)

- Update endpoint and project ID in `lib/core/init/appwrite_client.dart`.
- Ensure databases/collections used in services exist (see notes below).

## Running

```bash
flutter run -d <device_id>
```

Common options: `flutter run -d chrome` (web), `flutter run -d emulator-5554` (Android emulator), `flutter run -d ios` (iOS simulator).

## Testing and Quality

- Unit/widget tests: `flutter test`
- Static analysis: `flutter analyze`

## Building

- Android APK: `flutter build apk --release`
- Android App Bundle: `flutter build appbundle --release`
- iOS: `flutter build ios --release` (requires Xcode setup)

## Appwrite Notes

- Endpoint: `https://fra.cloud.appwrite.io/v1`
- Project ID: `696186f200091016180c`
- Database IDs observed in code (adjust to your Appwrite setup):
  - Expenses: database `143973bc-3217-4b7e-a1ca-05082dfde404`, collection `6962b3c600110543e89f`
  - Budgets: same database, collection `budgets`
- Update these IDs in feature services if your backend differs.

## Diagrams

- Architecture: see `ARCHITECTURE_DIAGRAM.md`
- Class diagram source: `CLASS_DIAGRAM.puml`

## Useful Scripts

- Clean build artifacts: `flutter clean`
- Update packages: `flutter pub upgrade`

## Troubleshooting

- If Appwrite health check fails at startup, verify endpoint/project and network access.
- If AI insights are empty, confirm `GEMINI_API_KEY` is set and Appwrite data is available.
- For notification issues, ensure permissions are granted and timezone data is available.
