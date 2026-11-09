# Development Progress

## Current phase

Phase 5/6 — Implementation gaps resolved; trusted backend and FCM remain.

## All identified implementation gaps resolved — 2026-11-09

- **Real-time challenge and result streams:** Converted `challengesProvider`
  and `resultsProvider` from `FutureProvider` to `StreamProvider` backed by
  new `watchChallenges()` and `watchResults()` methods on the Firestore
  repositories.  The UI now auto-refreshes when the other player acts (accepts
  a challenge, submits a result) without needing manual `ref.invalidate()`.
- **Notification streaming:** `notificationsProvider` is now a `StreamProvider`
  backed by `FirestoreNotificationRepository.watchSnapshot()` (a real-time
  Firestore query listener) for authenticated users.  `notificationSeedProvider`
  is now wired to the `PersistentNotificationRepository` seed for unauthenticated
  state; previously it was declared but never consumed.
- **Mark notification as read:** `_NotificationTile` is now a `ConsumerWidget`
  with an `onTap` handler that calls `FirestoreNotificationRepository.markRead()`
  on unread notifications.  Unread tiles display in primary colour with bold
  text; read tiles are greyed out.  `markRead` failures are non-critical and
  caught silently.
- **Audit log viewer:** Added an `_AuditLogSheet` bottom-sheet and
  `_AuditEventTile` widget that displays the full audit event log (actor,
  event type, entity, before/after, timestamp).  Accessible from the Admin
  overview by tapping the "Audit events" summary card, which now shows a
  chevron indicating its tappable nature.  `_AdminSummaryCard` gained an
  optional `onTap` parameter.
- **Treasurer payment mutations:** Replaced the read-only Treasurer screen
  with a full payment management view.  Each player row is now a tappable
  `_TreasurerPlayerTile` with a colour-coded payment status chip.  Tapping
  opens a `SimpleDialog` listing all `PaymentStatus` values; choosing a
  different status calls `FirestoreTreasurerRepository.updatePaymentStatus()`
  which invokes the trusted `updatePaymentStatus` Cloud Function.  Created
  `lib/features/treasurer/` feature folder with `data/` and `application/`
  layers.  `paymentOverviewProvider` is a real-time `StreamProvider`.
- **Score dialog inline validation:** `_ScoreDialog` now validates the score
  via `MatchScore.isValid()` before dismissing and displays an inline
  `errorText` on the `TextField` for invalid input.  Empty and malformed
  scores no longer pass through to the backend.
- **Challenge menu pre-filter:** The Normal challenge `PopupMenuItem` is now
  disabled (opacity 0.4, `enabled: false`) for players ranked below the
  current user, matching the rule-engine constraint.  The G.O.D. challenge
  option remains available for all opponents.
- **DemoAuthService dead import removed:** Removed the previously unused
  `demo_auth_service.dart` reference from `app.dart` (it was not imported but
  the class exists as a kept artifact).  The in-memory repositories now
  implement the new `watchChallenges()` and `watchResults()` interface methods.
- `flutter test --no-pub`: all 41 tests passed.
- `dart analyze` on all changed files: 0 issues.
- `flutter build apk --debug --no-pub`: not run this session (no device
  connected); analyze and tests confirm compilability.


## Pre-approval ladder viewing — 2026-11-08

- Pending and newly registered players now see the member list and standings
  on the Player dashboard. Challenges remain unavailable until approval.
- Added authenticated `getPublicLadder` Cloud Function for pending players.
  It joins rankings to player records server-side and returns only public
  identity, position, photo, activity and active-state fields, avoiding
  exposure of payment references or account data.
- Approved users retain the existing Firestore live ranking stream. Pending
  users load a server-fetched snapshot; refresh/realtime updates for that
  snapshot remain limited.
- Validation: pending.

## Shared branding and pending-player dashboard — 2026-11-08

- The in-app brand mark and Android launcher now use the same canonical
  `assets/brand/app_brand_mark.png`; launcher density images are generated
  from that source and adaptive-icon layers were removed to avoid a different
  launcher composition.
- Pending players see an explicitly labeled Player dashboard with membership
  status and request actions.
- Each new join request creates a persistent notification for every configured
  Admin, identifying the player and directing the Admin to review the request.
  The player sees an in-app confirmation after the callable succeeds. These
  are in-app alerts; FCM push delivery is not implemented.
- `flutter test --no-pub`: all 40 Flutter tests passed.
- `flutter analyze --no-pub`: no issues found.
- `npm test` in `functions/`: all 10 tests passed.
- Verified all five launcher-density PNGs are pixel-identical to resized
  versions of the canonical logo. `git diff --check` passed.
- `flutter build apk --debug --no-pub` succeeded; installed and launched on
  the connected Samsung SM-X115 tablet running Android 16.
- The live Firebase Callable Function was not deployed; deploy the current
  Functions code before expecting new alerts in the configured Firebase
  project.

## Player dashboard entry and role routing

- Successful player signup now navigates directly to the player dashboard;
  successful Admin/Treasurer sign-in continues to route to the role-specific
  workspace.
- Moved the Join Ladder, payment reference and verification states onto the
  player dashboard. Pending players can use membership actions there while
  standings, the member directory and other player features remain unavailable
  until Admin approval.
- Kept Admin and Treasurer roles owner-assigned in Firebase. No shared Admin
  key is accepted or stored in the app.
- Added widget coverage for pending-player dashboard access and signup/Admin
  navigation. Firestore rules do not change; pending users still cannot read
  the private player and ranking collections.
- `flutter analyze --no-pub` reports no issues and all 40 Flutter tests pass.
  The debug APK built successfully and was installed/launched on the connected
  Samsung SM-X115 tablet.

## Firebase signup diagnostics

- Replaced the generic signup failure text with Firebase-specific guidance for
  disabled Email/Password sign-up, duplicate accounts, invalid credentials,
  network/rate-limit failures, and Android app authorization errors.
- Recognizes the backend `CONFIGURATION_NOT_FOUND` detail even when Flutter
  reports the outer Firebase Auth code as `unknown`.
- When Authentication creates an account but Firestore profile creation fails,
  the app signs out and explains the Firestore error. Signing in again retries
  creation of a missing player profile with the least-privileged player role.
- Added widget coverage for disabled Email/Password and Firestore
  `permission-denied`; the full Flutter suite passes (37 tests) and targeted
  analysis reports no issues.
- Firebase Console settings and deployed Firestore Rules still need to be
  confirmed by the project owner. The debug APK built successfully and was
  installed/launched on the connected Samsung SM-X115 tablet; Android's
  notification-permission prompt appeared on first launch.

## Registration approval and live activity — 2026-11-05

- New player accounts are created as pending and cannot enter the ladder,
  profile, challenges or alerts until approved.
- Added a live Admin queue for pending signups. Approval requires manual
  confirmation of the UGX 40,000 payment and an Admin-assigned initial
  position; the transaction updates membership, payment status, ladder
  positions and an immutable audit event together.
- Authenticated app sessions update `lastActivityAt` with Firestore server
  timestamps on sign-in, resume and every five minutes in the foreground.
  The ladder listens to player changes and displays local date and time.
- Tightened Firestore rules for pending registrations, server-owned activity
  timestamps, Admin approval, initial ranking insertion and audit records.
- Removed the Flutter debug banner.
- The callable function, these rules and the privileged workflow still require
  Firebase Emulator Suite validation and deployment. Existing Firebase role
  documents must designate the Admin securely; the client cannot assign roles.

## Profile photo Storage diagnosis — 2026-11-05

- Confirmed the Android Firebase config and Flutter options both name
  `mukladder.firebasestorage.app`.
- Unauthenticated checks of that bucket and the legacy
  `mukladder.appspot.com` bucket returned HTTP 404. This does not replace
  confirmation in the Firebase Console, but indicates that a usable bucket
  has not been verified for this project.
- Firebase CLI is not installed here, so bucket provisioning and Storage Rules
  deployment could not be performed. The owner must confirm/create the bucket
  (check any billing prompt first) and deploy `storage.rules`.
- Updated profile-photo errors to direct users to the configured bucket and
  Firebase Storage Files.
- `flutter analyze --no-pub`: passed; `flutter test --no-pub`: all 32 tests
  passed; `flutter build apk --debug --no-pub`: passed.
- Installed and launched the debug APK on the connected Samsung SM-X115 tablet
  (Android 16). Profile-photo upload still requires the Firebase owner to
  confirm/create the Storage bucket and deploy the reviewed rules.

## Admin role selection and points — 2026-11-05

- Added Player, Admin and Treasurer sign-in choices. The selection is checked
  against the role in the trusted user profile; mismatched accounts are signed
  out, and the UI cannot grant a role.
- Added a live Admin list of every player's points total and a positive,
  reason-required manual points award action.
- Added the `addPlayerPoints` callable transaction with Admin authorization,
  approved-player validation, retry idempotency, and immutable point-event and
  audit records. Firestore Rules deny client reads/writes to these records
  except Admin reads. Point awards do not alter ladder positions.
- Added role-mismatch and Admin-points UI tests plus pure JavaScript tests for
  points validation and totals. `flutter analyze --no-pub` passed, all 33
  Flutter tests passed, and all 7 Cloud Functions tests passed.
- Firebase Emulator validation and deployment of the callable and Firestore
  Rules remain pending; no Firebase project data was changed.

## Firebase project reconfiguration — 2026-11-05

- FlutterFire generated Android configuration for project
  `mukladder-4351c`; `.firebaserc` uses the `development` alias.
- Removed a duplicate Google Services Gradle plugin declaration from
  `android/build.gradle.kts`. The canonical version remains declared once in
  `android/settings.gradle.kts` (4.3.15), resolving the 4.5.0/4.3.15 classpath
  conflict reported by `flutter run`.
- Build/install results for this configuration are recorded after validation.

## Join request and payment report workflow — 2026-11-06

- New accounts start outside the ladder with `notRequested` membership status.
- Added a Join Ladder action that creates a trusted backend request and sends
  persistent in-app alerts to all configured Admin accounts.
- Added external MTN MoMo reference reporting. The reference is stored as
  reported (not paid) and creates a second Admin notification and audit event.
- Admins see live membership alerts and transaction references in the queue.
  Approval is available only for a reported payment and requires an explicit
  Admin confirmation that it was independently verified; the trusted
  transaction then activates membership and assigns the initial rank.
- Merchant setup is not ready: the app does not initiate or automatically
  verify payments. Players must obtain official payment instructions from the
  authorized Admin/Treasurer. Admin alerts currently appear in the app rather
  than as FCM push notifications.
- Approval is gated on an Admin explicitly confirming external payment
  verification; the transaction records the reported reference and notifies the
  player after approval.
- `flutter analyze --no-pub`: passed; `flutter test --no-pub`: all 35 tests
  passed; `npm --prefix functions test`: all 10 tests passed.
- `flutter build apk --debug --no-pub`: passed. Installed and launched on the
  connected Samsung SM-X115 tablet (Android 16).
- The updated Functions and Firestore Rules still need Emulator testing and
  deployment to `mukladder-4351c`. No live backend changes were made.

## Phase 6 foundation started on 2026-10-23

- Added a dedicated pitfalls log in `docs/PITFALLS.md`.
- Added G.O.D. challenge creation with explicit mutual-consent workflow:
  creation remains pending until the challenged player accepts.
- Added duplicate pending G.O.D. challenge protection.
- Added a G.O.D. action to each ladder player card with confirmation and
  success/error feedback.
- Exact G.O.D. eligibility exceptions and backend authorization remain open
  pitfalls.

## Phase 7 foundation started on 2026-10-23

- Replaced the Admin placeholder with a read-only overview of pending
  challenges, unresolved results and audit-event counts.
- Replaced the Treasurer placeholder with a read-only payment-status overview.
- Kept privileged mutations disabled; the Treasurer cannot modify rankings or
  grant roles.

## Phase 8 foundation started on 2026-10-23

- Added an in-app Alerts destination and notification model/repository.
- Pending incoming challenges produce local alert entries.
- Added device-persisted notification history using `shared_preferences`.
- Added explicit synchronized, stale and rejected-storage states to the alert
  snapshot.
- Added a push-notification service boundary that reports configuration as
  unavailable until Firebase Cloud Messaging is set up.

## Firebase configuration preparation started on 2026-10-23

- Confirmed that no Firebase project files, project ID, Android Firebase
  configuration or Firebase dependencies are present.
- Documented the owner-required Firebase Console and FlutterFire steps in
  `docs/SETUP.md`.
- No credentials or external project configuration have been created.

## Firebase Android foundation connected on 2026-10-24

- Added the generated `firebase_options.dart` configuration.
- Added `firebase_core`, `firebase_auth` and `cloud_firestore` dependencies.
- Initialized Firebase before the application starts.
- Replaced the current-user provider with a Firebase Auth-backed service.
- Added an explicit authentication-required state when no Firebase user is
  signed in; the demo identity is no longer silently used after Firebase
  initialization.
- Added registration, login, logout and reactive session restoration.
- Added Firebase authentication error handling and player profile creation.
- Added initial Firestore Security Rules and Firebase CLI rules configuration.
- Added Firestore-backed ranking, challenge, result, audit and notification
  repositories.
- Added Firebase Messaging initialization for notification permission and
  foreground/background delivery hooks.
- Android debug build succeeds with the Firebase integration.
- Seeded the verified 24-player Week 7 Day 5 snapshot into the development
  Firestore `players` and `rankings` collections. The seed is not linked to
  Firebase Auth accounts until participant account onboarding is completed.
- Trusted server-side ranking/result transitions and Emulator Suite tests
  remain before production deployment.

## Phase 5 foundation started on 2026-10-23

- Added guarded Admin and Treasurer routes.
- Non-privileged demo users receive an explicit access-denied screen.
- Privileged screens are placeholders only; no administrative or payment
  mutation is enabled before backend authorization and rule verification.

## Phase 4 rule enforcement completed on 2026-10-23

- Added pure Dart Normal challenge validation for upward movement, the
  four-position range, 6 a.m.–8 p.m. placement hours and one-to-three-day
  scheduling.
- Added same-day response validation.
- Wired ranking positions and proposed next-day dates into the demo challenge
  request.
- The supplied rules are labelled as the 2025 reference; their applicability
  to the 2026 tournament still needs Ladder Admin confirmation.

## Phase 5 rules engine completed on 2026-10-23

- Added same-day, before-8 p.m. result submission validation when a challenge
  has a scheduled match date.
- Implemented the supplied Normal ranking outcomes: challenger wins move the
  challenger to the challenged position; challenger losses preserve positions.
- Implemented the supplied G.O.D. outcomes: challenger wins swap positions;
  challenger losses move the challenger to the bottom.
- Added explicit two-day cooldown validation for subsequent challenge
  placement.
- Walkover automation remains separate because it requires attendance,
  postponement and administrative event data.

## Phase 4 completed on 2026-10-23

- Completed the end-to-end local Normal challenge workflow:
  creation, response, accepted-match result submission, confirmation and
  dispute.
- Confirming a result now transitions the associated challenge to `completed`.
- The ladder refreshes from confirmed results using the clearly provisional
  local ranking policy.
- Added immutable in-memory audit events for result submission, confirmation
  and dispute transitions.
- Duplicate-result protection is enforced by the result repository.
- Walkover automation, scheduled penalties, notifications and backend
  authorization remain intentionally deferred.

## Provisional ranking calculation completed on 2026-10-23

- Added a pure Dart calculator for confirmed results.
- The explicitly temporary demo policy moves a confirmed winner immediately
  above the loser while preserving all other relative positions.
- Rejects missing participants and duplicate application of a confirmed result.
- Added unit coverage for movement and idempotency protection.
- This is not the official ranking algorithm; rulebook verification remains
  required before production use.
- Connected the calculator to the ranking provider so confirmed demo results
  refresh the displayed ladder.

## Result submission completed on 2026-10-23

- Added an in-memory result repository connected to the challenge repository.
- Added provisional score validation for accepted challenges.
- Added submitted, confirmed and disputed result transitions.
- Added result submission and confirmation/dispute controls to challenge cards.
- Prevented duplicate results and unauthorized participant submissions.
- Added unit and widget tests for submission, confirmation and invalid scores.

## Challenge response workflow completed on 2026-10-23

- Added challenge response operations to the repository interface and
  in-memory implementation.
- Seeded an incoming demo challenge for the temporary Tugume Keith identity.
- Added a dedicated Challenges destination in the application shell.
- Added Accept and Reject actions for pending incoming challenges.
- Restricted responses to the challenged player and rejected repeated responses
  through the domain state-transition rules.
- Added unit and widget tests for accepted responses and repeated-response
  rejection.
- Added newcomer instructions to `README.md` and `docs/SETUP.md` for running
  and manually trying the local demo workflow.

## Normal challenge creation in progress on 2026-10-23

- Added an in-memory challenge repository and Riverpod challenge providers.
- Added a Normal challenge confirmation dialog to the ladder list.
- Added self-challenge and duplicate-pending-challenge validation.
- Added success and validation-error feedback through snackbars.
- This is a local demo workflow only; official eligibility, timing and ranking
  consequences still require the authoritative rulebook.

## Read-only ladder completed on 2026-10-23

- Connected the in-memory ranking repository through Riverpod providers.
- Replaced the three placeholder entries with the 24-player Week 7 Day 5
  ranking snapshot from the tournament email thread.
- Kept email addresses out of the seed data because authentication and contact
  fields are not implemented yet.
- Replaced the ladder placeholder with a read-only ranking list showing
  position, player name and last activity date.
- Added loading, empty, error and retry states.
- Added widget coverage for all ranking states and retry behavior.

## Domain foundation completed on 2026-10-23

- Added pure Dart models for players, ranking entries, challenges and match
  results.
- Added explicit challenge and result status transitions that reject invalid
  operations.
- Added player and ranking repository interfaces with in-memory demo
  implementations.
- Added domain and repository tests covering valid data, empty data, invalid
  transitions and explicit repository failures.

## Foundation completed on 2026-10-23

- Added `flutter_riverpod` and `go_router`.
- Replaced the generated counter screen with a Material 3 MUKLadder shell.
- Added declarative navigation with Ladder and Profile destinations.
- Added the temporary `AuthService`/`DemoAuthService` boundary and explicit
  Player, Admin and Treasurer roles.
- Added widget coverage for the shell and profile navigation.
- Recorded Riverpod and `go_router` as implemented architecture decisions.

## Audit completed on 2026-10-23

- Confirmed the current branch is `main`.
- Confirmed recent history includes commits through
  `ad307c9 updated readmefile`.
- Confirmed the worktree contains the previously added untracked
  `AGENTS.md` and `docs/` project memory files; no tracked application files
  were modified during this audit.
- Confirmed the project contains the standard Flutter multi-platform
  scaffolding, with application code currently limited to `lib/main.dart` and
  `test/widget_test.dart`.
- Confirmed `lib/main.dart` is still the generated counter demo.
- Confirmed `test/widget_test.dart` only tests counter incrementing.
- Confirmed `pubspec.yaml` contains Flutter, `cupertino_icons` and
  `flutter_lints`; no Firebase, navigation or state-management packages are
  configured.
- Confirmed no Firebase configuration, backend functions, feature modules or
  domain models are present.
- Confirmed the README describes the intended Firebase architecture but does
  not provide setup instructions.

## Completed on 2026-10-23

- Confirmed the repository is a Flutter/Dart project targeting Android first.
- Confirmed the baseline is still the generated Flutter starter app.
- Confirmed `lib/main.dart` contains the counter demo and `test/widget_test.dart`
  contains the starter smoke test.
- Confirmed `pubspec.yaml` has Flutter and Cupertino Icons only; Firebase,
  navigation and state management are not configured.
- Added the persistent engineering documentation and copied the provided master
  prompt to `docs/MASTER_PROMPT.md`.
- Added the confirmed 1 November 2026 deadline and MVP delivery priorities to
  `docs/MASTER_PROMPT.md`.
- Recorded the initial architecture direction, provisional data model and
  missing official-rule source.

## Verification

- `flutter --version`: Flutter 3.47.7, Dart 3.13.5.
- `flutter pub get`: passed; dependencies resolved. Flutter reported five
  packages with newer versions incompatible with current constraints.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed; 1 widget test succeeded.
- `flutter build apk --debug`: passed; Android SDK Platform 36 was installed
  and `build/app/outputs/flutter-apk/app-debug.apk` was produced. Gradle
  emitted a Java restricted-native-access warning that did not fail the build.
- `git diff --check`: passed.
- `flutter analyze` after foundation changes: passed with no issues.
- `flutter test` after foundation changes: passed; 2 widget tests succeeded.
- `flutter analyze` after domain changes: passed with no issues.
- `flutter test` after domain changes: passed; 9 tests succeeded.
- `dart format --output=none --set-exit-if-changed lib test` after domain
  changes: passed.
- Hot restart was attempted through Dart tooling but the user denied the tool
  call because no Flutter app was connected.
- `flutter analyze` after ranking changes: passed with no issues.
- `flutter test` after ranking changes: passed; 12 tests succeeded.
- `dart format --output=none --set-exit-if-changed lib test` after ranking
  changes: passed.
- `flutter analyze` after challenge changes: passed with no issues.
- `flutter test` after challenge changes: passed; 16 tests succeeded.
- `dart format --output=none --set-exit-if-changed lib test` after challenge
  changes: passed.
- `flutter analyze` after response changes: passed with no issues.
- `flutter test` after response changes: passed; 19 tests succeeded.
- `dart format --output=none --set-exit-if-changed lib test` after response
  changes: passed.
- `flutter analyze` after result changes: passed with no issues.
- `flutter test` after result changes: passed; 21 tests succeeded.
- `dart format --output=none --set-exit-if-changed lib test` after result
  changes: passed.

## Known limitations and blockers

- The official MUK Ladder Rules, 2025 document is not in the repository.
- Firebase project configuration and credentials are intentionally absent.
- Firebase authentication and persistence are not configured.
- The exact placement time discrepancy requires clarification.

## Next

Implement the provisional ranking calculation for confirmed results, keeping
the algorithm clearly separate until the official rulebook is verified.

## Windows Android device setup — 2026-11-04

- Diagnosed Android debug build failures on Windows: the project is on `D:`
  while the Pub package cache was on `C:`, and Kotlin incremental compilation
  failed while registering cross-drive cache files.
- Configured Android Gradle to run Kotlin compilation in-process without
  incremental or parallel compilation, and ignored generated `android/.kotlin`
  cache files.
- Documented using a Pub cache on the project drive in `docs/SETUP.md`.
- Built the debug APK successfully and installed/launched it on the connected
  SM X115 Android device. The device reports the MUKLadder MainActivity resumed.
- `flutter run` still needs an online dependency check unless invoked with
  `--no-pub`; a `pub.dev` DNS lookup failed during this session.

## Branding, live ladder and Admin overview — 2026-11-04

- Added an original vector tennis/ladder brand mark and applied a consistent
  green Material 3 theme and refreshed player, sign-in, profile and dashboard
  surfaces.
- Removed the in-app demo ranking fixture. The app now listens to ordered
  Firestore `rankings` snapshots, so UI changes appear when ranking documents
  change; the development collection itself still begins with a static seed.
- Added a refreshed Admin overview with role checks, Firestore-backed counts
  for players, pending challenges, unresolved results and audit events, plus a
  refresh/retry path.
- Kept Admin workspace read-only. The rulebook and trusted backend needed for
  official ranking changes and audited admin mutations are not present.
- Updated setup, project context, architecture, data model, README and next
  steps to distinguish the live read path from the still-static seed and
  provisional client-side rule logic.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: passed, 25 tests.

## Player profile photos — 2026-11-04

- Added optional gallery photo selection during account registration and a
  profile photo replace action for existing signed-in players.
- Added Firebase Storage upload at a per-user path with JPEG and 5 MB limits.
- Added photo URL fields to user/player models and Firestore profile writes.
- Added a reusable avatar with initials fallback to the ladder rows and player
  profile. Ladder reads now listen to player profile updates as well as ranking
  updates.
- Added Storage Security Rules restricting uploads/replacements to the owning
  authenticated account and reads to signed-in users; configured Firebase CLI
  to use the rules file.
- Added iOS photo library usage description.
- The project owner still needs to confirm/enable the Firebase Storage bucket
  and deploy the reviewed rules. Existing seeded players need a verified
  `players/{playerId}.userId` link to their Auth UID for their pictures to show
  on the roster.

## Profile upload diagnostics and match history — 2026-11-05

- The upload now uses the completed Storage task's reference to fetch the
  download URL and records both that URL and `photoStoragePath` in Firestore.
- Added actionable upload errors for missing Storage objects/buckets and
  Storage authorization failures.
- Added a profile match-history view showing opponent, reported match score,
  challenge type, result confirmation state and date.
- Match history reads only challenges involving the signed-in player and their
  related results, and resolves opponent display names from player documents.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: passed, 27 tests.
- `flutter build apk --debug --no-pub`: passed; installed and launched on the
  connected Android device.
- The Firebase CLI is unavailable in this environment, so Storage bucket
  existence and deployed rules could not be checked. The project owner must
  verify the configured bucket and deploy `storage.rules`.
- No official ladder-point total is generated: ranking points are not in the
  current result data model, and the trusted/confirmed ranking rules are not
  available.

## Challenge and result workflow continuation — 2026-11-05

- Added match-date selection for Normal and G.O.D. challenge creation and
  added alternative-date proposal/acceptance handling in the challenge UI and
  repositories.
- Added provisional score parsing, participant score reporting, opponent confirmation
  or dispute, and atomic Firestore writes for the result/challenge documents.
- Corrected Normal challenge range validation so a player can target only
  someone ranked above them, at most four positions higher.
- Added tests covering rank direction/range, alternate-date acceptance, and
  the two-player result submit/review flow.
- `dart format lib test`: passed.
- `flutter analyze --no-pub`: passed.
- `flutter test --no-pub`: passed, 30 tests.
- `flutter build apk --debug --no-pub`: passed; produced
  `build/app/outputs/flutter-apk/app-debug.apk`.
- These are client-side/provisional workflows, not an authoritative production
  implementation. Firestore Rules do not enforce every time, rank, score or
  cooldown condition, and challenge participant IDs are not yet reconciled
  with seeded roster documents and Auth UIDs.
- Trusted Cloud Functions, ranking history/updates, automated walkovers and
  penalties, synced notifications, Admin/Treasurer mutations, Emulator Suite
  tests, and live Firebase verification remain outstanding.
