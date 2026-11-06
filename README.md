# MUKLadder

A mobile application for automated management, challenge coordination and ranking of the Makerere University Tennis Ladder Tournament.

**BSE 3106 – Mobile Networks and Computing | Capstone Project | AY 2026/2027**

## Problem
The Makerere University Tennis Ladder is governed by a detailed set of 12 formal rules (MUK Ladder Rules, 2025) [1] administered by a Ladder Admin (Mr. Kibirige Dean) and a Treasurer. While the rules themselves are clear and designed to ensure fairness, the operational model is almost entirely manual and communication-heavy. This creates a series of friction points that actively undermine participation, ranking integrity, and administrative sustainability.


## Solution
MUKLadder is being built to automate the official MUK Ladder rules while
keeping ranking changes reliable and auditable. The Android app uses Firebase
Auth and Firestore. Its ladder screen listens to the development ranking
collection; the starter ranking is seeded data, not an automated rules engine.

## Key Features
- Live ladder ranking (offline-first)
- Challenge placement (Normal + Game of Death)
- Same-day confirmation + automatic walkover
- Result submission + automated ranking engine
- 2-day cool-down enforcement
- Admin & Treasurer dashboard
- Player profile photos
- Player match history
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

### Try the current app

The current app requires a sign-in to the configured Firebase project.

1. Open the **Ladder** tab.
2. View the current ranking feed. The development Firestore collection
   currently contains a 24-player Week 7 Day 5 seed.
3. Open **Profile** to see your account and any role-based workspace links.
4. Admin accounts can review pending signups, confirm payment and assign an
   initial ladder position. This requires the deployed `approvePlayerRegistration`
   Cloud Function and Firestore Rules.
5. On sign-up, players can optionally choose a profile photo; signed-in users
   can change it from **Profile**.
6. **Profile** displays submitted match scores with each opponent and result
   status.

### Run the checks

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`.

## Current limitations

- The ranking feed is live, but its initial development data is a static seed.
- Profile photo uploads require the project owner to enable Firebase Storage
  and deploy `storage.rules`; existing roster accounts must be linked by
  verified Auth UID to show their image in the ladder.
- Match history displays recorded tennis scores. Official ladder points are
  not calculated until the tournament scoring rules and trusted ranking
  backend are confirmed.
- The full official rules document and confirmation of 2026 rule applicability
  are still needed.
- Initial registration approval uses a callable backend workflow, but the
  function and revised Firestore Rules must be deployed before it works against
  Firebase. Result-based ranking transitions remain unimplemented.
- Firebase CLI is required to deploy `functions/approvePlayerRegistration`
  and `firestore.rules`; no Firebase deployment is performed by the app build.
- Scheduled walkovers, rule-authoritative result ranking updates and event-
  driven push notifications are not implemented yet.
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
