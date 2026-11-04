# Next Steps

## Current state — 4 November 2026

- The Android app uses Firebase Authentication and Firestore.
- The ladder screen streams ordered documents from the `rankings` collection;
  its current 24-player development seed is still static source data.
- The ranking calculator is provisional. No trusted backend updates official
  positions from match results yet.
- The Admin workspace is role-guarded and read-only. It shows live operational
  counts; approvals, result decisions, role changes and ranking overrides are
  intentionally unavailable until trusted server workflows exist.
- The complete official rulebook is not in the repository, and the 2025 rules'
  applicability to the 2026 tournament is unconfirmed.

## 1. Confirm the authoritative rules and admin responsibilities

- Obtain the complete MUK Ladder Rules, 2025 source document.
- Confirm with the Ladder Admin or lecturer whether those rules govern the
  2026/2027 tournament and clarify any differing or ambiguous time windows.
- Confirm which actions belong to the Ladder Admin and which belong to the
  Treasurer, including registration, result review, walkovers, ranking
  corrections and payment-status updates.
- Do not implement official game outcomes or privileged admin mutations from
  summaries or assumptions.

## 2. Implement trusted ranking and result workflows

- Translate only confirmed rule clauses into a pure-Dart, independently tested
  rule engine.
- Add trusted Cloud Functions or equivalent server transactions for result
  confirmation, ranking changes, cooldowns, deadlines, walkovers and audit
  records.
- Configure and test the Firebase Emulator Suite and Firestore rules before
  enabling official operations.
- Preserve ranking versions and make scheduled or retried operations
  idempotent.

## 3. Complete the Admin workspace

- Keep client role checks for navigation, but enforce all access and mutations
  through Firebase Security Rules and trusted backend authorization.
- Add only the administration workflows approved in step 1.
- Write an audit event for every privileged change and test forbidden access.
- Maintain a separate Treasurer view and restrict it to approved payment-status
  duties.

## 4. Integrate and verify the end-to-end app

- Replace seed-only ranking setup with backend-generated ranking records
  derived from verified results.
- Test online/offline states, authorization and ranking updates on an Android
  device.
- Run `flutter analyze`, `flutter test` and a debug Android build after each
  related implementation batch.
