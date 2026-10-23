# Testing Guide

## Local checks

From the repository root:

```text
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Run the smallest relevant command while developing, then run all applicable
checks before completing a feature. Record actual outcomes in
[PROGRESS.md](PROGRESS.md).

## Test layers

- **Unit tests:** Pure Dart domain models, validation and rule-engine
  calculations. These must not require Flutter rendering or live Firebase.
- **Widget tests:** Screens, loading/empty/error states and user interactions
  using fakes.
- **Integration tests:** Authentication and challenge-to-ranking flows against
  Firebase emulators where feasible.
- **Security tests:** Firestore rules must cover both permitted and forbidden
  reads/writes for Player, Admin and Treasurer roles.

## Important scenarios

Test deadline boundaries in `Africa/Kampala`, duplicate/retried scheduled jobs,
invalid state transitions, concurrent ranking changes, stale offline data,
rejected writes and unauthorized role/ranking mutations.

## Current baseline

The repository currently contains only the generated counter widget test.
Firebase, emulator and device checks are not yet configured.

