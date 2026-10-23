# Development Setup

## Prerequisites

- Flutter SDK compatible with the SDK constraint in `pubspec.yaml`
- Dart SDK supplied by Flutter
- Android Studio or an Android SDK/emulator
- Git
- Firebase CLI only when Firebase setup begins

## Local project

1. Clone the repository and enter its root.
2. Run `flutter pub get`.
3. Run `flutter analyze` and `flutter test`.
4. Start an Android emulator or connect an approved development device.
5. Run `flutter run`.

## Firebase configuration

Firebase setup is not yet complete. When it begins, use separate development
and production projects where feasible, configure the Android app through the
standard FlutterFire process, and prefer the Firebase Emulator Suite for local
development and security-rule tests.

Never commit service-account keys, private keys, passwords, `.env` files or
production credentials. Do not enable billing or make destructive production
changes without explicit approval.

## Troubleshooting

If dependencies are stale, run `flutter pub get`. If the Android toolchain is
not detected, run `flutter doctor` and resolve only the relevant missing
component. Record environment-specific blockers in `docs/PROGRESS.md`.

