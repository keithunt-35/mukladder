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

- **Completed:** Normal challenge creation, challenge responses, result
  submission, confirmation/dispute, challenge completion after confirmation,
  and provisional ranking refresh.
- **Deferred:** Official rule enforcement, Firebase persistence, audit-event
  storage and administrative review workflows.

## 4. Configure Firebase and implement authentication

- **Objective:** Add registration, login, logout, session restoration and safe
  role-aware routing.
- **Acceptance:** Unauthorized users cannot access protected data or grant
  themselves roles; tests cover validation and authorization.
- **Dependencies:** Tasks 1–3 and Firebase project configuration.
- **Blocked:** Yes until Firebase setup is available.
