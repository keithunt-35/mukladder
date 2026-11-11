# Development Progress

## Current phase

Phase 5 — Trusted ranking confirmation and Rule 10 prep (feature freeze window).

## Firebase Emulator local loop — 11 November 2026

- Enabled `EmulatorConfig.useEmulator = true` (Android emulator host `10.0.2.2`)
  for Auth, Firestore, Functions and Storage.
- Added `emulators` block to `firebase.json`.
- Emulator suite started for project `mukladder-4351c`.
- Seeded Auth/Firestore users via `scripts/create-test-users.js`.

## Trusted match confirmation — 11 November 2026

- Hardened Cloud Function `confirmMatchResult` to:
  - require an accepted challenge and opponent confirmation
  - recalculate Normal / G.O.D. rankings via `ranking_engine`
  - rewrite ranking documents with `effectiveAt`, `sourceResultId` and version bump
  - stamp winner `cooldownStartedAt` and both players' `lastChallengeAt`
  - write participant notifications and an audit event with before/after positions
- Wired Android `FirestoreResultRepository.transitionResult` so **confirm** calls
  `confirmMatchResult` instead of a client Firestore write.
- Locked Firestore rules: clients may dispute submitted scores, but may not
  confirm results or complete challenges (Cloud Functions only).
- Rankings collection remains client write-denied.
- Added provisional Rule 10 planner (`inactivity_plan.js`) with unit tests and a
  daily Kampala scheduled job `applyInactivityDrops`.
- Ladder UI prefers server `cooldownStartedAt` when present.

## Verification

- `node --test ranking_engine.test.js inactivity_plan.test.js`: 12 passed
- `dart analyze` on changed libraries: no issues
- `flutter test test/domain_test.dart`: all passed

## Known limitations and blockers

- Official MUK Ladder Rules, 2025 source PDF is still not in the repository;
  Rule 10 inactivity remains provisional pending Admin confirmation.
- Functions / rules still need deploy to the selected Firebase project and a
  live Android confirm → rank-change smoke test.
- Automatic 8 p.m. result nullification and full FCM fan-out for every event
  are not finished.
- Real-user usability sessions are not documented as completed.

## Next

See [NEXT_STEPS.md](NEXT_STEPS.md).
