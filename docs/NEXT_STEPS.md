# Next Steps

Tasks are ordered by dependency and risk.

The confirmed delivery deadline is **1 November 2026**. Prioritize a complete,
testable end-to-end MVP over unfinished stretch features, and reserve 30–31
October for stabilization and demonstration preparation where possible.

## 1. Implement provisional ranking calculation — completed

- **Objective:** Apply a clearly labelled provisional ranking calculation after
  a result is confirmed, without presenting it as the official rule algorithm.
- **Acceptance:** A confirmed result can be calculated predictably, duplicate
  application is rejected, and the calculation has unit tests.
- **Dependencies:** None.
- **Status:** Pure Dart calculation is implemented and covered by unit tests.
- **Blocked:** Production use remains blocked until the official rules are
  available.

## 2. Integrate provisional ranking refresh into the demo workflow

- **Objective:** Refresh the local ladder after a result is confirmed and make
  the temporary policy visible in the demo UI.
- **Acceptance:** Confirming the seeded demo result changes the displayed
  ranking, and refreshing or repeating the action does not apply it twice.
- **Dependencies:** Task 1.
- **Status:** Implemented by deriving the ladder from confirmed in-memory
  results and invalidating the ranking provider after result transitions.

## 3. Finalize the data model

- **Objective:** Review `DATA_MODEL.md` against the concept paper and rulebook.
- **Acceptance:** Collections, fields, relationships, validation and security
  boundaries are approved and documented.
- **Dependencies:** Tasks 1–2.
- **Blocked:** Yes, if the official rules or stakeholder decisions are missing.

## Phase 4 — Challenges and results — completed

- **Completed:** Normal challenge creation with supplied position/time rules,
  same-day challenge responses, result submission, confirmation/dispute,
  challenge completion after confirmation, and provisional ranking refresh.
- **Deferred:** G.O.D. challenges, Firebase persistence, backend-authoritative
  enforcement, scheduled walkovers/cooldowns and administrative review
  workflows.

## 4. Configure Firebase and implement authentication

- **Objective:** Add registration, login, logout, session restoration and safe
  role-aware routing.
- **Acceptance:** Unauthorized users cannot access protected data or grant
  themselves roles; tests cover validation and authorization.
- **Dependencies:** Tasks 1–3 and Firebase project configuration.
- **Blocked:** Yes until Firebase setup is available.

## Phase 5 — Administration and advanced rules

### 5. Add verified administration workflows

- **Status:** Foundation started with guarded Admin and Treasurer routes.
- **Next:** Confirm the official rulebook and role responsibilities before
  implementing walkovers, G.O.D. challenges, cooldowns, penalties, payment
  updates or administrative overrides.
- **Constraint:** Privileged mutations must be backend-authorized and audited;
  the current demo routes intentionally provide no mutation controls.

## Phase 5 — Results and ranking engine status

- **Completed locally:** Result submission, opponent confirmation/dispute,
  duplicate protection, result cutoff validation, Normal/G.O.D. ranking
  outcomes, two-day cooldown validation, provisional ranking refresh,
  challenge completion after confirmation, and immutable audit events.
- **Blocked pending workflow support:** Walkover automation still requires
  attendance, postponement and administrative event data.
- **Production requirement:** These blocked rules must be implemented in trusted
  backend transactions or scheduled jobs, not trusted to client-side state.

## Phase 6 — G.O.D. challenges and time-bound automation

- **Started:** Added local G.O.D. challenge creation and pending mutual-consent
  workflow.
- **Next:** Add explicit G.O.D. UI controls, consent audit events, and verified
  deadline handling.
- **Blocked:** Exact G.O.D. eligibility exceptions, walkover evidence and
  trusted scheduled jobs require backend implementation and confirmation of
  2026 rule applicability.
- **Pitfalls:** See [PITFALLS.md](PITFALLS.md) before continuing.

## Phase 7 — Admin and Treasurer dashboards

- **Started:** Added role-guarded read-only Admin and Treasurer dashboards.
- **Admin view:** Pending challenge count, unresolved result count and audit
  event count.
- **Treasurer view:** Player payment-status flags without payment credentials
  or payment processing.
- **Deferred:** Registration approvals, walkover decisions, ranking overrides,
  payment updates and role changes until Firebase authorization and audited
  backend operations are available.

## Phase 8 — Notifications and offline hardening

- **Started:** Added local in-app Alerts for pending incoming challenges.
- **Implemented locally:** Device-persisted notification history, freshness
  metadata, stale/rejected-storage indicators and explicit push-service
  configuration boundary.
- **Deferred:** Firebase synchronization, conflict resolution and actual
  foreground/background/terminated-app delivery.
- **Constraint:** Local alerts must not be presented as push notifications or
  synchronized backend data.

## Firebase foundation — owner setup required

- **Blocked until owner setup:** Create/select a development Firebase project,
  register the Android app, enable Email/Password Authentication, create a
  development Firestore database, install the Firebase and FlutterFire CLIs,
  and run `flutterfire configure`.
- **Do not provide:** Passwords, service-account JSON, private keys, admin
  credentials or `.env` files.
- **After setup:** Return with the generated project ID and confirmation that
  FlutterFire configuration completed. Then implement Firebase initialization,
  authentication, Firestore rules and repositories in that order.

## Firebase foundation — connected

- **Completed:** Android Firebase configuration, Firebase startup
  initialization, Firebase Auth identity boundary, email/password
  registration, login, logout, session restoration, player profile creation
  initial Firestore rules, Firestore-backed ranking/challenge/result/audit
  repositories, Firestore notification history and FCM initialization.
- **Current behavior:** Users without a Firebase session see an explicit
  authentication-required state.
- **Next:** Add trusted server-side ranking/result transitions, configure the
  Firebase Emulator Suite, and test/deploy the rules after review.
