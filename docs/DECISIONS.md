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
