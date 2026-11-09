# Architecture Decision Records

Decisions are recorded here before they become hidden assumptions. Statuses:
**proposed**, **approved** and **implemented**.

## ADR-001 — Flutter/Dart Android-first application

- **Date:** 2026-10-23
- **Status:** Implemented (baseline)
- **Problem:** Select the application platform and implementation environment.
- **Options:** Native Android, cross-platform Flutter, web-first application.
- **Decision:** Retain the existing Flutter/Dart project and target Android first.
- **Reason:** The repository already contains a Flutter application and Android
  scaffolding; this preserves existing work and matches the project scope.
- **Trade-offs:** Some platform-specific integration may still be required.

## ADR-002 — Firebase backend direction

- **Date:** 2026-10-23
- **Status:** Proposed
- **Problem:** Provide authentication, synchronized data, trusted automation and
  notifications.
- **Options:** Firebase, a custom hosted API, local-only storage.
- **Decision:** Use Firebase Auth, Firestore, Cloud Functions and FCM.
- **Reason:** This matches the approved project direction and supplies backend
  authorization, transactions, scheduled jobs and mobile notifications.
- **Trade-offs:** Requires project configuration, security rules, emulator
  testing and external Firebase setup. No production credentials are present.

## ADR-003 — Firestore offline persistence first

- **Date:** 2026-10-23
- **Status:** Proposed
- **Problem:** Support offline viewing without compromising official state.
- **Options:** Firestore cache, Hive, SQLite.
- **Decision:** Begin with Firestore-supported offline persistence and add a
  local database only if measured requirements justify it.
- **Reason:** It minimizes dependencies while supporting synchronized reads.
- **Trade-offs:** Cache behavior and pending writes must be tested carefully.

## ADR-004 — State management package

- **Date:** 2026-10-23
- **Status:** Implemented
- **Problem:** Choose a maintainable state-management approach.
- **Options:** Riverpod, Bloc, Provider.
- **Decision:** Use Riverpod through `flutter_riverpod`.
- **Reason:** It provides testable dependency injection and application state
  without requiring generated code for the initial MVP.
- **Trade-offs:** The team must learn Riverpod's provider lifecycle and avoid
  putting business logic directly in widgets.

## ADR-005 — Navigation package

- **Date:** 2026-10-23
- **Status:** Implemented
- **Problem:** Provide simple, testable navigation for the MVP.
- **Options:** Flutter Navigator APIs, `go_router`, another routing package.
- **Decision:** Use `go_router` with an indexed shell for the main destinations.
- **Reason:** It provides declarative routes and a straightforward path to
  role-aware routing when real authentication is added.
- **Trade-offs:** Route configuration is an additional abstraction for the
  small initial app.

## ADR-006 — Firebase Storage for profile photos

- **Date:** 2026-11-04
- **Status:** Implemented in app; Firebase bucket/rules setup pending
- **Problem:** Let players upload a profile image that can be shown on their
  profile and next to their name in the ladder.
- **Options:** Store image files in Firestore, use a third-party image host, or
  use the project's Firebase Storage bucket.
- **Decision:** Use Firebase Storage with one JPEG at
  `profilePhotos/{uid}/profile.jpg`, an upload-size limit of 5 MB, and rules
  limiting writes to the authenticated owner. Store the download URL on the
  Firestore user profile and linked player record.
- **Reason:** The app already uses Firebase Auth and Firestore, and Storage
  provides object storage with Firebase Authentication rules.
- **Trade-offs:** Storage must be enabled and its rules deployed in the Firebase
  project. Existing seeded roster entries need a verified Auth UID link before
  their account photo can appear in the ladder. Firebase plan or billing
  requirements must be checked by the project owner.

## ADR-007 — Admin-verified registration and initial position

- **Date:** 2026-11-05
- **Status:** Implemented as a Callable Function; Emulator Suite validation
  and deployment pending
- **Problem:** New accounts must not join the active ladder until the
  UGX 40,000 fee is received and an authorized Admin accepts them.
- **Decision:** Keep player signups pending. A Firebase Callable Function
  verifies the caller's Admin role, records the Admin's manual payment
  confirmation and selected initial position in one audited Firestore
  transaction. The transaction shifts later positions and rejects gaps or
  duplicate positions. Client Firestore rules continue to deny ranking writes.
- **Reason:** The paper describes payment as a status flag, excludes a payment
  gateway from the MVP, and the user confirmed that initial positions are
  assigned manually by the Admin.
- **Trade-offs:** Admin approval is only available after the function and
  Firestore Rules are Emulator-tested and deployed. This workflow does not
  implement ranking changes from match results or validate payment evidence.

## ADR-008 — Server-timestamped app activity

- **Date:** 2026-11-05
- **Status:** Implemented in app; rules deployment pending
- **Problem:** Ladder activity timestamps must represent actual app use rather
  than seeded or hardcoded dates.
- **Decision:** Write `lastActivityAt` with Firestore server timestamps on
  sign-in, app resume and every five minutes while foregrounded; render missing
  values as no recorded activity.
- **Reason:** Server time avoids relying on user-device clocks, and the
  heartbeat keeps active sessions current.
- **Trade-offs:** Each signed-in foreground session writes at a five-minute
  interval; actual updates require the revised rules to be deployed.

## ADR-009 — Explicit role selection and audited manual player points

- **Date:** 2026-11-05
- **Status:** Implemented in app and Functions; deployment pending
- **Problem:** Let users choose the intended sign-in role and let Admins
  inspect player point totals and award points without inventing match-scoring
  or ranking rules.
- **Decision:** Show Player, Admin and Treasurer sign-in modes, then compare
  the selection with the role loaded from the trusted user profile. A mismatch
  signs out and is rejected; selecting Admin never grants that role. Admins
  can add positive whole-number points with a required reason. The backend
  records each adjustment transactionally in a total, immutable event and
  audit record. Point totals do not automatically change ladder positions.
- **Reason:** The existing project has no approved point-scoring formula and
  explicitly protects ranking changes from client writes.
- **Trade-offs:** Deploy `addPlayerPoints` and the updated Firestore Rules
  before using these dashboard features. Awarding points from match results
  requires separate confirmation of official scoring rules.

## ADR-010 — MTN MoMo external payment report and Admin verification

- **Date:** 2026-11-06
- **Status:** Implemented as a pending-membership workflow; deployment and
  merchant integration pending
- **Problem:** Let a new player request to join, notify Admins, and report a
  UGX 40,000 subscription payment without claiming an unverified payment is
  confirmed.
- **Decision:** Signup creates a non-member account with no join request.
  `requestToJoinLadder` sends persistent in-app notifications to Admins.
  Because no MTN MoMo merchant account is configured, the app does not take a
  payment; the player must obtain official payment instructions externally
  and submit a transaction reference. `reportLadderPayment` notifies Admins,
  but marks payment only as reported. An Admin must verify the transaction
  externally, confirm that verification, assign a position, and approve via
  the existing trusted transaction. Only then is membership activated.
- **Reason:** The payment provider was selected as MTN MoMo, but the user
  confirmed the merchant account is not ready. A reference submitted by a
  player is not proof of settlement.
- **Trade-offs:** Alerts are persisted and live in the Admin dashboard; FCM
  push delivery and actual MTN MoMo collection/callback verification are not
  part of this phase. Deploy the new callable functions and Firestore Rules
  before using the workflow.
