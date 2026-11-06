# Next Steps

## Current state — 6 November 2026

- The Android app uses Firebase Authentication and Firestore.
- The ladder screen streams ordered documents from the `rankings` collection;
  its current 24-player development seed is still static source data.
- The ranking calculator is provisional. No trusted backend updates official
  positions from match results yet.
- Normal/G.O.D. challenge creation now asks for a match date; alternative-date
  proposals and a provisional result report/confirmation flow are present.
  Their client checks are not authoritative and have not been tested against
  the Firestore Emulator.
- The Admin workspace receives join/payment-report alerts and shows submitted
  MTN MoMo references. Admins must verify payment externally before the trusted
  approval transaction assigns an initial position and activates membership.
  The merchant account is not configured, so the app does not charge or
  automatically verify payments.
- The Admin workspace now lists all player point totals and supports audited
  manual point awards. The total is separate from ladder position. Deploy the
  `addPlayerPoints` callable and updated Firestore Rules before relying on it;
  match-derived points are not implemented until official scoring rules are
  confirmed.
- Admin role sign-in is a UI selection checked against the trusted role in the
  user profile; it does not provision Admin accounts. Have the project owner
  assign Admin roles through a trusted process. Firebase Emulator validation
  and deployment of the updated Functions/Rules are still required.
- New accounts can request to join; Admins receive persistent in-app alerts.
  Players report an external MTN MoMo transaction reference and Admins must
  verify payment before approval. The merchant account is not configured, so
  there are no in-app charges or automatic payment verification yet. FCM push
  delivery and Emulator validation remain future work.
- Profile photos can be selected at registration or changed from Profile.
  Android configuration now targets `mukladder-4351c` and
  `mukladder-4351c.firebasestorage.app`; confirm/create that bucket in Firebase
  Console and deploy `storage.rules` before uploads can work. Seeded roster
  players also need verified Auth UID links.
- Player profiles show the score string and opponent for recorded results.
  Official points/ranking totals are not calculated; confirm the applicable
  rules and implement the trusted ranking backend before adding them.
- The complete official rulebook is not in the repository, and the 2025 rules'
  applicability to the 2026 tournament is unconfirmed.
- Seed ranking player IDs do not reliably match Firebase Auth UIDs. Existing
  roster account linking and challenge identity reconciliation still require
  verified account-to-roster associations.

## 1. Confirm the authoritative rules and admin responsibilities

- Obtain the complete MUK Ladder Rules, 2025 source document.
- Confirm with the Ladder Admin or lecturer whether those rules govern the
  2026/2027 tournament and clarify any differing or ambiguous time windows.
- For the provisional implementation, use the user's confirmed 6 a.m.–8 p.m.
  challenge-placement window and treat the concept paper as a provisional
  specification. This does not confirm the official rules for production.
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
- First reconcile participant identity by verified `players.userId` links and
  route challenge/result mutations through authenticated server operations;
  do not enable official ranking changes from client writes.
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

- Confirm the development Firebase Storage bucket/plan with the project owner,
  then deploy the reviewed Storage rules.
- Verify profile-photo upload and Firestore URL/path persistence with an
  authenticated Android account after Storage is enabled.
- The Firebase CLI is not installed here and no Firebase Console changes were
  made. If Firebase reports `object-not-found`, verify/create the Storage
  bucket named in the Android Firebase config and deploy `storage.rules`
  before retrying the upload.
- Link registered participant accounts to their existing roster player
  documents using verified identities, not display-name matching.

## Registration approval and activity update — 5 November 2026

- New accounts start without a join request. An Admin manually verifies the
  UGX 40,000 fee after the player submits an external payment reference, then
  assigns an initial position in the Admin workspace.
- The approval uses an atomic Firestore transaction and writes an audit event.
  Pending accounts are gated from the player experience; user profile updates
  make that approval visible without signing in again.
- `lastActivityAt` is written using Firestore server time on sign-in, app
  resume and every five minutes while foregrounded. The ladder receives those
  changes from its player-document stream.
- The debug banner is disabled.
- Next: test membership/payment functions, `firestore.rules`, and the Admin
  transaction with the Firebase Emulator Suite, deploy the reviewed rules and
  functions to the selected `mukladder-4351c` project, and verify with separate
  Admin, requesting-player and approved-player accounts.
- Existing ranking records must have consecutive integer positions before an
  Admin can insert a new member. The Admin transaction rejects gaps or
  duplicates rather than silently rewriting inconsistent ladder state.
- The app records a payment reference for manual verification; it does not
  collect or automatically validate money. Firebase roles, MTN MoMo merchant
  credentials and production project provisioning remain owner actions.
- `npm audit --omit=dev` reports six moderate transitive vulnerabilities under
  the Firebase Admin/Google Cloud dependency tree. `npm audit fix` did not
  resolve them without breaking-version upgrades; review remediation before
  production deployment.
- Replace seed-only ranking setup with backend-generated ranking records
  derived from verified results.
- Test online/offline states, authorization and ranking updates on an Android
  device.
- Run `flutter analyze`, `flutter test` and a debug Android build after each
  related implementation batch.
