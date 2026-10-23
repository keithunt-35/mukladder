# Next Steps

Tasks are ordered by dependency and risk.

The confirmed delivery deadline is **1 November 2026**. Prioritize a complete,
testable end-to-end MVP over unfinished stretch features, and reserve 30–31
October for stabilization and demonstration preparation where possible.

## 1. Finalize stack and Firebase plan

- **Objective:** Resolve state management, Firebase environment strategy and
  emulator approach.
- **Acceptance:** A recorded ADR names the selected packages and the setup
  process contains no secrets or destructive production actions.
- **Dependencies:** None.
- **Blocked:** Partially blocked until the team confirms Firebase project access.

## 2. Finalize the data model

- **Objective:** Review `DATA_MODEL.md` against the concept paper and rulebook.
- **Acceptance:** Collections, fields, relationships, validation and security
  boundaries are approved and documented.
- **Dependencies:** Task 1.
- **Blocked:** Yes, if the official rules or stakeholder decisions are missing.

## 3. Establish the application foundation

- **Objective:** Replace the starter shell with a minimal Material 3 app shell,
  navigation and consistent loading/error patterns.
- **Acceptance:** The app launches, navigation works and analysis/tests pass.
- **Dependencies:** Task 1.
- **Blocked:** No.

## 4. Implement authentication

- **Objective:** Add registration, login, logout, session restoration and safe
  role-aware routing.
- **Acceptance:** Unauthorized users cannot access protected data or grant
  themselves roles; tests cover validation and authorization.
- **Dependencies:** Tasks 1–3 and Firebase configuration.
- **Blocked:** Yes until Firebase setup is available.
