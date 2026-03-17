# Bunk Alert

A feature-rich Flutter mobile application that helps students track and manage their academic attendance. It provides real-time risk assessment, predictive analytics, collaborative study groups, and cloud synchronization — so you always know where you stand with your attendance.

## Features

- **Attendance Tracking** — Record present, absent, or cancelled status for each class with date-based record keeping
- **Real-time Risk Assessment** — Get instant alerts when attendance drops near or below your target percentage
- **Predictive Analytics** — Calculate how many classes you can safely skip or need to attend to stay above target
- **Recovery Plans** — Generate personalized recovery plans with class-count targets to reach your desired percentage
- **Timetable Management** — Manage your weekly class schedule with customizable time slots for each day
- **Smart Reminders** — Receive notifications before classes start (configurable lead time, default 10 min)
- **Visual Analytics** — View attendance trends via line charts, pie charts, heatmaps, and progress indicators
- **Study Groups** — Create or join study groups via invite codes, compare attendance on leaderboards
- **Cloud Sync** — Automatic two-way synchronization with Firebase, with full offline support via a local database
- **Data Export** — Export attendance records to CSV and share them
- **Multi-Subject Management** — Per-subject targets, color coding, and archiving for inactive subjects
- **Theming** — Light, dark, and system theme modes with Material 3 design

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter / Dart (SDK ≥ 3.11.1) |
| **State Management** | Riverpod 2.5 + Riverpod Generator |
| **Navigation** | Go Router 17.1 |
| **Local Database** | Isar 3.1 (NoSQL) |
| **Backend** | Firebase (Auth, Firestore, Messaging) |
| **Authentication** | Firebase Auth + Google Sign-In |
| **Notifications** | Flutter Local Notifications + Firebase Cloud Messaging |
| **Cloud Functions** | Node.js 18 (Firebase Functions) |
| **Charts** | FL Chart 1.1 |
| **UI** | Material 3, Flutter Animate, Phosphor Icons, Google Fonts |
| **Connectivity** | Connectivity Plus + Internet Connection Checker |
| **Testing** | Flutter Test + Mocktail |

## Project Structure

```
lib/
├── main.dart                  # App entry point & bootstrap
├── app.dart                   # App configuration
├── firebase_options.dart      # Firebase config (auto-generated)
├── core/                      # Core utilities and configuration
│   ├── config/                # Google Sign-In config
│   ├── constants/             # App, color, and string constants
│   ├── enums/                 # AttendanceStatus, SyncStatus, etc.
│   ├── extensions/            # DateTime, Double, String extensions
│   ├── router/                # Go Router route definitions
│   ├── theme/                 # Colors, typography, spacing
│   └── utils/                 # BunkCalculator, RiskCalculator, CSV exporter
├── data/                      # Data layer
│   ├── database/              # Isar local database service
│   ├── export/                # CSV export functionality
│   ├── firebase/              # Firestore & Auth services
│   ├── models/                # Data models (Isar-annotated)
│   ├── notifications/         # FCM and local notification scheduling
│   ├── repositories/          # Repository pattern implementations
│   └── sync/                  # Cloud & offline sync services
├── domain/                    # Domain layer
│   ├── entities/              # Clean architecture entities
│   └── usecases/              # Business logic (9 use cases)
├── features/                  # Feature modules
│   ├── auth/                  # Login & sign-up screens
│   ├── dashboard/             # Home / dashboard screen
│   ├── subjects/              # Subject management
│   ├── timetable/             # Class schedule management
│   ├── analytics/             # Attendance analytics & charts
│   ├── social/                # Study groups & leaderboards
│   └── settings/              # App settings & preferences
└── shared/                    # Shared utilities and widgets
    ├── auth/                  # Auth state management
    ├── hooks/                 # Custom Flutter hooks
    ├── providers/             # Global Riverpod providers
    ├── utils/                 # Error mapping utilities
    └── widgets/               # Reusable UI components
```

## Architecture

The project follows **Clean Architecture** with a **Repository Pattern** and **Riverpod** for dependency injection and state management.

```
┌─────────────────────────────────────────┐
│            Presentation Layer           │
│   (Screens, Widgets, Feature Providers) │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│             Domain Layer                │
│        (Use Cases, Entities)            │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│              Data Layer                 │
│   (Repositories, Services, Models)      │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Infrastructure                │
│  (Firebase, Isar DB, SharedPreferences) │
└─────────────────────────────────────────┘
```

**Key design patterns:** Repository, Use Case, Provider (Riverpod), Observer (Streams), Singleton (Services).

**Sync strategy:** The local Isar database is the primary source of truth. Changes are queued with a `pending` sync status and pushed to Firestore when connectivity is available. Conflicts are resolved with a last-write-wins approach using timestamps.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.11.1
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) for platform tooling
- [Node.js](https://nodejs.org/) ≥ 18 (for Firebase Cloud Functions)
- A [Firebase](https://console.firebase.google.com/) project

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/naasheet/Bunk-Alert.git
cd Bunk-Alert
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Run code generation

The project uses code generation for Isar models and Riverpod providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Configure Firebase

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password and Google Sign-In providers).
3. Enable **Cloud Firestore**.
4. Enable **Firebase Cloud Messaging**.
5. Install and run the FlutterFire CLI to generate configuration:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

This will generate/update `lib/firebase_options.dart` and the platform-specific config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).

### 5. Set up Cloud Functions (optional)

```bash
cd functions
npm install
cd ..
```

Deploy with:

```bash
firebase deploy --only functions
```

### 6. Install iOS dependencies (macOS only)

```bash
cd ios
pod install
cd ..
```

### 7. Run the app

```bash
flutter run
```

## Firebase Cloud Functions

The `functions/` directory contains two callable Cloud Functions:

| Function | Purpose |
|---|---|
| `sendGroupAlert` | Sends a push notification to all members of a study group via an FCM topic |
| `sendAttendanceWarning` | Sends an attendance warning notification to a specific user's devices via FCM tokens |

## App Configuration

Runtime settings are managed through `SharedPreferences` and are configurable in the Settings screen:

| Setting | Default | Description |
|---|---|---|
| Global target percentage | 75% | Minimum attendance target across all subjects |
| Class reminders | Enabled | Notification before each class starts |
| Risk alerts | Enabled | Notification when attendance drops near target |
| Reminder lead time | 10 min | Minutes before class to trigger reminder |
| Theme mode | System | Light, dark, or follow system setting |

Per-subject target percentages can be configured individually.

## Testing

Run the existing unit and widget tests with:

```bash
flutter test
```

Test files are located in the `test/` directory:

- `test/core/utils/bunk_calculator_test.dart` — BunkCalculator logic tests
- `test/core/utils/risk_calculator_test.dart` — RiskCalculator logic tests
- `test/widgets/subject_list_card_test.dart` — SubjectListCard widget test
- `test/widgets/attendance_action_row_test.dart` — AttendanceActionRow widget test

Integration tests are in the `integration_test/` directory.

## Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ipa --release
```

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`.
3. Make your changes and ensure all tests pass: `flutter test`.
4. Run the analyzer: `flutter analyze`.
5. Commit your changes: `git commit -m "Add my feature"`.
6. Push to your branch: `git push origin feature/my-feature`.
7. Open a Pull Request.
