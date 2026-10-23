# MUKLadder Project Context

## Purpose

MUKLadder automates the Makerere University Tennis Ladder Tournament, which
currently depends on manual communication, spreadsheets and administrator
follow-up. The app should provide a reliable source of truth for players,
challenges, results, rankings and administrative decisions.

## Stakeholders and roles

- **Player:** views the ladder, places and responds to challenges, submits
  results and monitors activity.
- **Ladder Admin:** manages registrations, exceptions, challenges, results and
  official ladder operations.
- **Treasurer:** manages and verifies payment-status information.

Roles must be assigned by an authorized backend process. A client must not be
able to grant itself a privileged role.

## Scope

Essential scope includes authentication and role management, player profiles,
live rankings, Normal and G.O.D. challenges, response and result workflows,
walkovers, ranking updates, cooldowns, inactivity penalties, notifications,
admin/Treasurer views, payment-status flags, offline reading and audit history.

Court booking, payment gateways, SMS fallback and multi-sport support are
stretch goals and must wait until essential workflows are stable.

## Target and team

- Course: BSE 3106 — Mobile Networks and Computing
- Academic year: 2026/2027
- Primary platform: Android
- Team: Tugume Keith Kaganda, Niwamanya Joel, Moola Joseph

## Current confirmed state (23 October 2026)

The repository is an existing Flutter project using the default starter
application. It has a `lib/main.dart`, a basic widget smoke test and a minimal
`pubspec.yaml`. Firebase, authentication, application navigation, a state
management package and feature modules have not yet been configured.

The implementation must be built incrementally. The complete official MUK
Ladder Rules, 2025 document is not present in the repository, so rule summaries
must not be treated as a substitute for the rulebook.

## Working technology direction

- Flutter/Dart, Android first
- Firebase Auth, Cloud Firestore, Cloud Functions and FCM
- Firestore offline persistence initially
- Pure Dart rule engine for independently testable business rules
- State-management package and exact local-storage approach: unresolved;
  see [DECISIONS.md](DECISIONS.md)

