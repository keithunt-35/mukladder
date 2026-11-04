# Development Progress

## Current phase

Phase 5 — Administration and advanced rules preparation.

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
