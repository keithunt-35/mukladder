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

## Current confirmed state (4 November 2026)

Firebase Authentication, Firestore and FCM are configured in the Android app.
The ladder screen reads ordered ranking documents from Firestore and now
subscribes to ranking changes. The development Firestore currently contains a
24-player seed snapshot; it is still data supplied as a starting point, not a
ranking engine. Authentication and role-guarded read-only Admin/Treasurer
screens are present.

The full official MUK Ladder Rules, 2025 document is not in the repository,
and its applicability to the 2026 tournament is unconfirmed. The provisional
Dart ranking calculator is not authoritative. Trusted backend ranking
transitions, audited admin mutations and Emulator Suite security tests remain
unimplemented. Do not treat the seeded positions or client-side demo logic as
official game outcomes.

## Working technology direction

- Flutter/Dart, Android first
- Firebase Auth, Cloud Firestore, Cloud Functions and FCM
- Firestore offline persistence initially
- Pure Dart rule engine for independently testable business rules
- State-management package and exact local-storage approach: unresolved;
  see [DECISIONS.md](DECISIONS.md)
