# MUKLadder Architecture

## Status

This document describes the target architecture and the currently verified
baseline. Firebase and feature modules are not yet implemented.

## Client structure

Organize `lib/` by feature, with these responsibilities:

- `app/`: application shell, theme and navigation.
- `core/`: shared errors, utilities and reusable widgets.
- `features/<feature>/presentation/`: screens and widgets.
- `features/<feature>/application/`: workflows and state providers.
- `features/<feature>/domain/`: models, validation and pure business rules.
- `features/<feature>/data/`: repositories, Firestore access and mapping.

The current foundation uses Riverpod for dependency injection/state access and
`go_router` for declarative navigation. The main shell currently exposes the
ladder and profile destinations.

Expected feature areas are auth, players, ladder, challenges, results,
notifications, admin and treasurer. Do not create empty structure without a
feature need.

## Data flow

The UI invokes application workflows. Workflows validate input and use domain
logic, then call repositories. Repositories read/write Firebase services and
map external data to domain models. Rule-sensitive mutations are sent to
trusted backend functions or transactions; the client never directly changes
official rankings.

## Backend responsibilities

- Firebase Auth authenticates users.
- Firestore stores player, challenge, result, ranking, notification and audit
  data.
- Cloud Functions perform privileged ranking changes, deadline handling,
  cooldowns, inactivity penalties and notifications.
- Firestore Security Rules enforce authentication, ownership and role
  boundaries.
- Scheduled operations must be idempotent and safe to retry.

## Authentication and authorization

Authentication will use Firebase Auth. Roles are stored and enforced through a
trusted administrative workflow and backend security rules, not a role supplied
by the client. Admin and Treasurer capabilities must be checked separately.

Until Firebase Auth is configured, the application uses an explicitly
temporary `AuthService` interface with a `DemoAuthService` implementation.
Feature code reads the current user through that interface so the demo identity
can later be replaced without rewriting screens.

## Offline strategy

Start with Firestore-supported offline persistence for previously synchronized
read data. The UI must distinguish synchronized data, potentially stale cache,
pending writes and rejected writes. Deadline-sensitive challenges and results
must be revalidated by the server before they become official. A separate local
database is not approved unless testing shows the built-in cache is
insufficient.

## Rule engine

Ranking and challenge rules belong in pure Dart functions/classes with explicit
inputs and outputs. They must be testable without Flutter rendering or a live
Firebase project. The exact algorithm and timing conditions require verification
against the official rulebook before implementation.
