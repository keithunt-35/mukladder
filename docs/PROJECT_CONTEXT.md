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

## Current confirmed state (6 November 2026)

Firebase Authentication, Firestore and FCM are configured in the Android app.
The ladder screen reads ordered ranking documents from Firestore and now
subscribes to ranking changes. The development Firestore currently contains a
24-player seed snapshot; it is still data supplied as a starting point, not a
ranking engine. Authentication and role-guarded Admin/Treasurer screens are
present. New player accounts can request to join; Admins receive persistent
in-app alerts. A player can submit an external MTN MoMo reference, which is a
payment claim, not proof of settlement. An Admin must verify the payment
externally, then approve and assign an initial position through the trusted
backend. The MTN MoMo merchant account is not configured, so the app does not
take or automatically verify payments. App activity timestamps use Firestore
server time and refresh on sign-in, resume and while the app remains
foregrounded. Registration also supports optional profile-photo uploads to
Firebase Storage; the profile and ladder can display photos for players whose
roster documents are linked to their Auth UID. Storage bucket setup and rules
deployment remain owner actions.
The player profile now reads submitted match scores, result status and
opponents from Firestore; this is match-score history, not an authoritative
ladder-point total.

The full official MUK Ladder Rules, 2025 document is not in the repository,
and its applicability to the 2026 tournament is unconfirmed. The provisional
Dart ranking calculator is not authoritative. Trusted backend match-result
ranking transitions and Emulator Suite security tests remain unimplemented.
The membership/points functions and Firestore rules have not yet been
Emulator-tested or deployed. Firebase Android app configuration now targets
project `mukladder-4351c`; backend services still require provisioning. Do not
treat the seeded positions or client-side demo logic as official game outcomes.

## Working technology direction

- Flutter/Dart, Android first
- Firebase Auth, Cloud Firestore, Cloud Functions and FCM
- Firestore offline persistence initially
- Pure Dart rule engine for independently testable business rules
- State-management package and exact local-storage approach: unresolved;
  see [DECISIONS.md](DECISIONS.md)
