# Development Setup

## Prerequisites

- Flutter 3.47.7 or a compatible newer Flutter SDK
- Dart 3.13.5 supplied by Flutter
- Android Studio or an Android SDK/emulator
- Git

Verify the environment:

```bash
flutter doctor
flutter --version
```

Resolve Android toolchain issues reported by `flutter doctor` before trying to
run the application.

## Local project

1. Clone the repository and enter its root.
2. Run `flutter pub get`.
3. List available targets with `flutter devices`.
4. Start an Android emulator or connect an approved development device.
5. Run `flutter run` or `flutter run -d <device-id>`.

The Android app is connected to the development Firebase project. Sign in with
an authorized project account or register a player account to use the app.
Firebase configuration is checked into this workspace; never copy private
credentials into the client or commit service-account files.

### Windows: Kotlin cache errors when project and Pub cache are on different drives

If Android builds fail with `this and base files have different roots` or
`Could not close incremental caches`, put the Dart Pub cache on the same drive
as the project. For a project in `D:\mukladder`, open a PowerShell terminal and
run:

```powershell
$env:PUB_CACHE = 'D:\PubCache'
flutter pub get
flutter run -d <device-id>
```

Set `PUB_CACHE` to `D:\PubCache` in Windows user environment variables to keep
using that cache in new terminals. The Android Gradle configuration disables
parallel and incremental Kotlin compilation to avoid cache registration
failures on this setup; the first build may take longer.

## What to try

1. Open **Ladder** to view the Firestore ranking feed. The development
   collection currently starts with a 24-player Week 7 Day 5 seed.
2. The screen refreshes when ranking documents change in Firestore.
3. Open **Profile** to view the signed-in account. Authorized Admin and
   Treasurer accounts see their role-specific workspace links.

The seed is not recalculated by a trusted rules engine yet. The official rule
document and a trusted backend are required before game results can update
official positions.

## Local verification

Run these commands from the project root:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The generated debug APK is at
`build/app/outputs/flutter-apk/app-debug.apk`.

## Firebase configuration

Firebase is configured for the current development workspace. Use these steps
only when configuring another development environment or replacing the Firebase
project.

### What the project owner must do

1. Create or select a Firebase project in the Firebase Console. Use a
   development project first; do not use a production project for this MVP
   setup.
2. Register the Android application using the exact Android application ID
   from `android/app/build.gradle.kts` (or the project's current Gradle
   configuration). Do not guess this value.
3. Enable **Authentication > Sign-in method > Email/Password**.
4. Create a Firestore database in development mode only. The initial rules
   must be replaced before real participant data is used.
5. Install or make available the Firebase CLI and FlutterFire CLI on the
   development machine.
6. From the repository root, run `flutterfire configure`, select the
   development project and Android platform, and allow it to generate the
   Flutter configuration file.
7. Return the generated project ID and confirm that configuration completed.
   Do not send passwords, service-account keys, private keys or `.env` files.

### What the implementation now does

- Uses Firebase Auth, Firestore and Firebase Messaging.
- Initializes Firebase before the application starts.
- Provides registration, login, logout and session restoration.
- Uses Firestore repositories for ranking, challenges, results, audit reads and
  notification history.
- Protects client access with the checked-in Firestore Security Rules.
- Requests notification permission and registers foreground/background FCM
  handlers.

The remaining production requirement is a trusted backend for ranking
transactions, official result transitions and audit-event writes. The mobile
client deliberately cannot write rankings or audit events.

### Required configuration artifacts

The FlutterFire-generated `lib/firebase_options.dart` and Android Firebase
configuration are project configuration, not credentials. They may be
committed when generated for this repository, subject to the team's repository
policy. Service-account JSON files, private keys, passwords, `.env` files and
admin credentials must never be committed.

Firebase configuration is now present for the Android development project.
The app initializes Firebase at startup and includes email/password
registration, login, logout and session restoration.

To deploy the checked-in Firestore rules after reviewing them:

```bash
firebase use mukladder
firebase deploy --only firestore:rules
```

Do not deploy rules to a production project without explicit approval.

Never commit service-account keys, private keys, passwords, `.env` files or
production credentials. Do not enable billing or make destructive production
changes without explicit approval.

## Troubleshooting

If dependencies are stale, run `flutter pub get`. If the Android toolchain is
not detected, run `flutter doctor` and resolve only the relevant missing
component. If multiple devices are connected, pass a device ID to
`flutter run -d`. Record environment-specific blockers in
`docs/PROGRESS.md`.
