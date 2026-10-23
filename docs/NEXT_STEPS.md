# Next Steps

Tasks are ordered by dependency and risk.

The confirmed delivery deadline is **1 November 2026**. Prioritize a complete,
testable end-to-end MVP over unfinished stretch features, and reserve 30–31
October for stabilization and demonstration preparation where possible.

## 1. Implement Normal challenge creation

- **Objective:** Add Normal challenge creation using the verified subset of
  eligibility rules and the existing domain state model.
- **Acceptance:** Valid demo challenges can be created, invalid/duplicate
  requests are rejected, and behavior is covered by unit/widget tests.
- **Dependencies:** None.
- **Blocked:** Partially blocked until the official rules are available.

## 2. Finalize the data model

- **Objective:** Review `DATA_MODEL.md` against the concept paper and rulebook.
- **Acceptance:** Collections, fields, relationships, validation and security
  boundaries are approved and documented.
- **Dependencies:** Task 1.
- **Blocked:** Yes, if the official rules or stakeholder decisions are missing.

## 3. Configure Firebase and implement authentication

- **Objective:** Add registration, login, logout, session restoration and safe
  role-aware routing.
- **Acceptance:** Unauthorized users cannot access protected data or grant
  themselves roles; tests cover validation and authorization.
- **Dependencies:** Tasks 1–3 and Firebase project configuration.
- **Blocked:** Yes until Firebase setup is available.
