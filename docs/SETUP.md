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

Firebase setup is not yet complete. When it begins, use separate development
and production projects where feasible, configure the Android app through the
standard FlutterFire process, and prefer the Firebase Emulator Suite for local
development and security-rule tests.

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
