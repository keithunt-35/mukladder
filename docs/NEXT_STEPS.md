# Next Steps

## Current state — 9 November 2026

All previously identified implementation gaps in the Flutter client have been
resolved.  The remaining work falls into three categories: trusted backend
Cloud Functions that must be deployed, the FCM push delivery pipeline, and
the walkover/inactivity automation.

## 1. Deploy the required Cloud Functions

The following callable functions are invoked by the app but must be deployed
to Firebase project `mukladder-4351c` before they will work on a live device:

| Function | Purpose |
|---|---|
| `requestToJoinLadder` | Player join request + Admin alert |
| `reportLadderPayment` | MTN MoMo reference submission |
| `approvePlayerRegistration` | Admin approval + rank assignment |
| `addPlayerPoints` | Admin manual points award |
| `getPublicLadder` | Pending-player public ladder view |
| `updatePaymentStatus` | **New** — Treasurer payment-status flag update |

`updatePaymentStatus` is the newest addition; it must be written and deployed
alongside the others.  It must enforce Treasurer role authorization, validate
the incoming `status` against the `PaymentStatus` enum values, update the
matching `players` document, and write an audit event.

Acceptance criteria: Firebase Emulator Suite validates the function and the
Firestore Rules before deploying to production.

## 2. Implement FCM push notification delivery

The `firebaseMessagingBackgroundHandler` is intentionally empty; FCM tokens
are never saved to Firestore.  To complete push delivery:
- Save the device FCM token to `users/{uid}/fcmTokens` on sign-in and on
  token refresh.
- Send push payloads from Cloud Functions (join request, payment report,
  challenge created, result submitted) via the Firebase Admin SDK.
- Handle `onMessage` (foreground), `onMessageOpenedApp` (background tap) and
  `getInitialMessage` (terminated app) in `FirebaseMessagingService`.

## 3. Implement walkovers and inactivity penalties (server-side)

These require Firestore-triggered or scheduled Cloud Functions:
- **Walkover:** When a pending challenge has not been responded to by end of
  placement day, mark it expired and award a walkover result to the challenger.
  This requires server-clock enforcement — not client-side.
- **Inactivity penalty:** A scheduled function (e.g., weekly) should check
  players whose `lastActivityAt` has not been updated within the threshold and
  apply the official ranking penalty.  Make the job idempotent (mark processed
  with a timestamp so re-running does not double-penalize).

Confirm the exact trigger conditions and penalty consequences with the Ladder
Admin before implementing either job.

## 4. Trusted ranking updates from confirmed results

Confirming a result currently marks it `confirmed` and the challenge
`completed` but does not move any player's position in the `rankings`
collection.  A Cloud Function triggered by a result reaching `confirmed`
status should apply the official Normal/G.O.D. ranking algorithm atomically.

## 5. Firebase Emulator validation and production deployment

All Cloud Functions and Firestore Security Rules should be tested with the
Firebase Emulator Suite before any production deployment.  This includes:
- Membership approval transaction
- Points award idempotency
- Payment status update (Treasurer only)
- Challenge/result participant identity checks
- Walkover and inactivity jobs (once implemented)

## 6. Roster identity reconciliation

Seed `players/{playerId}.userId` for the 24 existing seeded players by linking
their Auth UIDs.  Until this is done, profile photos and challenge participant
identity resolution will not work correctly for seeded roster players.

## 7. Firebase Storage bucket and rules deployment

Confirm the `mukladder-4351c.firebasestorage.app` bucket exists in Firebase
Console and deploy `storage.rules`.  Profile photo uploads will fail until this
is done.



- The Android app uses Firebase Authentication and Firestore.
- The in-app logo and Android launcher now share the canonical
  `assets/brand/app_brand_mark.png`. The connected tablet needs a visual
  home-screen check after installing the latest build.
- Pending players can view their Player dashboard and request membership;
  each new request creates a persistent in-app alert for every configured
  Admin. FCM push alerts are not implemented. Deploy the current Cloud
  Function before relying on new alerts in Firebase.
- Pending and newly registered players can view the member list and standings
  using the authenticated `getPublicLadder` callable. Deploy Cloud Functions
  to the configured Firebase project before expecting the public ladder fetch
  to work on a live installation.
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
  user profile; it does not provision Admin accounts and does not use a shared
  secret key. Have the project owner assign Admin roles through a trusted
  process. Firebase Emulator validation and deployment of the updated
  Functions/Rules are still required.
- New accounts can request to join; Admins receive persistent in-app alerts.
  Players report an external MTN MoMo transaction reference and Admins must
  verify payment before approval. The merchant account is not configured, so
  there are no in-app charges or automatic payment verification yet. FCM push
  delivery and Emulator validation remain future work.
- Successful player signup opens the player dashboard, where the Join Ladder
  and payment workflow and public ladder standings are shown. Challenges and
  other member-only operations remain unavailable until Admin approval.
- If signup reports that Email/Password is disabled, enable that provider in
  Firebase Console for `mukladder-4351c`. If Firestore reports
  `permission-denied`, deploy the current `firestore.rules` to that project.
  An Auth account may already exist; sign in with that email to retry creating
  its missing player profile rather than trying to register it again.
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
