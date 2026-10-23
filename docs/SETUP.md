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

The current prototype starts in Demo mode. No Firebase project, login account
or secret configuration is needed to try the implemented local flow.

## What to try

1. Open **Ladder** and review the 24-player Week 7 Day 5 ranking snapshot.
2. Tap **Challenge** beside another player and confirm the request.
3. Open **Challenges** and accept or reject the seeded incoming challenge.
4. Open **Profile** to inspect the temporary Tugume Keith demo identity.

Demo records are held in memory and reset after an app restart.

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

Firebase setup is not yet complete. Follow this sequence when starting it.

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

### What the implementation will do after that

- Add Firebase Auth, Firestore and FCM Flutter dependencies.
- Replace `DemoAuthService` behind the existing `AuthService` boundary.
- Add Firebase initialization in the application entry point.
- Add registration, login, logout and session restoration.
- Add Firestore repositories and server-authoritative data boundaries.
- Add Firestore Security Rules and emulator configuration.
- Add role checks that cannot be changed by the client.
- Add FCM initialization only after notification permissions and platform
  configuration are confirmed.

### Required configuration artifacts

The FlutterFire-generated `lib/firebase_options.dart` and Android Firebase
configuration are project configuration, not credentials. They may be
committed when generated for this repository, subject to the team's repository
policy. Service-account JSON files, private keys, passwords, `.env` files and
admin credentials must never be committed.

Do not attempt Firebase configuration to try the current demo. It is a later
development step.

Never commit service-account keys, private keys, passwords, `.env` files or
production credentials. Do not enable billing or make destructive production
changes without explicit approval.

## Troubleshooting

If dependencies are stale, run `flutter pub get`. If the Android toolchain is
not detected, run `flutter doctor` and resolve only the relevant missing
component. If multiple devices are connected, pass a device ID to
`flutter run -d`. Record environment-specific blockers in
`docs/PROGRESS.md`.
