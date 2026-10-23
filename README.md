# MUKLadder

A mobile application for automated management, challenge coordination and ranking of the Makerere University Tennis Ladder Tournament.

**BSE 3106 – Mobile Networks and Computing | Capstone Project | AY 2026/2027**

## Problem
The Makerere University Tennis Ladder is governed by a detailed set of 12 formal rules (MUK Ladder Rules, 2025) [1] administered by a Ladder Admin (Mr. Kibirige Dean) and a Treasurer. While the rules themselves are clear and designed to ensure fairness, the operational model is almost entirely manual and communication-heavy. This creates a series of friction points that actively undermine participation, ranking integrity, and administrative sustainability.


## Solution
MUKLadder is being built to automate the official MUK Ladder rules while
keeping ranking changes reliable and auditable. The current prototype uses
local demo data; Firebase integration is not configured yet.

## Key Features
- Live ladder ranking (offline-first)
- Challenge placement (Normal + Game of Death)
- Same-day confirmation + automatic walkover
- Result submission + automated ranking engine
- 2-day cool-down enforcement
- Admin & Treasurer dashboard
- Push notifications

## Tech Stack
- **Frontend**: Flutter (Dart) – Android first
- **Backend**: Firebase (Auth, Cloud Firestore, Cloud Functions, FCM)
- **Offline direction**: Firestore-supported caching first
- **State management**: Riverpod
- **Navigation**: go_router

## Team
- Tugume Keith Kaganda
- Niwamanya Joel
- Moola Joseph

## Lecturer
Drake Patrick Mirembe, PhD

## Project Status
🚧 In development – local MVP foundation and core challenge workflow

## Try the project locally

### Prerequisites

- Flutter 3.47.7 or a compatible newer Flutter SDK
- Dart 3.13.5 or the Dart SDK supplied by Flutter
- Android Studio with an Android SDK and emulator, or a connected Android
  device
- Git

Check the installation with:

```bash
flutter doctor
flutter --version
```

### Install and run

From the repository root:

```bash
flutter pub get
flutter run
```

If more than one device is available, list them and choose one:

```bash
flutter devices
flutter run -d <device-id>
```

### Try the current demo flow

The current app runs in clearly labelled **Demo mode** and does not require a
Firebase project or login account.

1. Open the **Ladder** tab.
2. Review the Week 7 Day 5 ranking snapshot, seeded from the tournament email:
   - 24 real tournament participants are listed in their reported positions.
   - The temporary demo identity is mapped to Tugume Keith.
3. Tap **Challenge** beside another player.
4. Confirm **Send challenge**.
5. Open the **Challenges** tab.
6. Review the seeded incoming challenge.
7. Tap **Accept** or **Reject**.
8. Open **Profile** to view the temporary demo identity for Tugume Keith.

Demo changes are stored in memory and reset when the application restarts. They
are not official tournament records.

### Run the checks

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`.

## Current limitations

- Firebase Authentication and Firestore are not configured.
- Data is held in memory for the current demo.
- There is no real registration or login flow yet.
- Result submission, ranking updates, notifications and administrative
  dashboards are not implemented yet.
- Rule-dependent behavior must be verified against the official MUK Ladder
  Rules, 2025 document before being treated as final.

## Setup Instructions
For fuller setup and safety notes, see [docs/SETUP.md](docs/SETUP.md).

## Documentation

- [Project context](docs/PROJECT_CONTEXT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Testing guide](docs/TESTING.md)
- [Development progress](docs/PROGRESS.md)
- [Next steps](docs/NEXT_STEPS.md)
