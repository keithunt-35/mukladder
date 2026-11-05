# Implementation Pitfalls and Follow-up Work

This file records known limitations, assumptions and risks that should be
reviewed before production release. Items are not silently treated as solved.

## Open pitfalls

1. **Rules version:** The supplied rules are labelled 2025 while the active
   tournament data is for 2026. Confirm applicability with the Ladder Admin.
2. **Trusted backend missing:** Current repositories are in-memory. Ranking,
   cooldown, deadline, consent and audit enforcement must move to trusted
   Firebase transactions or Cloud Functions before production.
3. **Africa/Kampala time zone:** Date validation currently uses the runtime
   `DateTime` values. Normalize all deadline calculations explicitly to
   `Africa/Kampala`.
4. **Walkover evidence:** Walkovers need attendance, late-arrival,
   postponement and administrator decision data; they must not be inferred
   from a missing result.
5. **G.O.D. eligibility:** The supplied text confirms mutual agreement but does
   not define every eligibility exception. The current pending/accepted state
   is only a local consent representation.
6. **Ranking history:** The demo recalculates a list but does not yet persist
   versioned ranking history or a transaction ID.
7. **Participant identity:** The development Firestore seed uses stable
   `player-1` through `player-24` IDs and is not linked to verified Firebase
   Auth accounts yet.
8. **Test coverage:** Tests have intentionally not been run during the latest
   implementation steps; run the suite before relying on these changes.
9. **Notifications are local-first:** Alert history now persists on the
   device and exposes stale/rejected states, but it does not synchronize with
   Firebase or resolve conflicts across devices.
10. **Push delivery is unavailable:** Background and terminated-app delivery
   requires Firebase Cloud Messaging, platform configuration and permissions.
11. **Authentication uses Firebase profile roles:** Registration and sign-in
   screens are implemented. Missing or unavailable profiles must never grant
   privileged roles; server-side authorization remains authoritative.
12. **Ranking seed is static:** The app now listens to Firestore ranking
   snapshots, but the development 24-player seed is not recalculated from
   results. The provisional client calculator is not the official rules
   engine.
13. **Admin workspace is read-only:** The dashboard shows Firestore-backed
   counts. No trusted, audited backend actions exist yet for approvals,
   result decisions, ranking changes, role updates or payment changes.
14. **Profile photo Storage setup:** Client support and `storage.rules` are
   implemented, but the project owner must confirm the Firebase Storage
   bucket/plan and deploy the rules. Existing seeded roster players are not
   linked to Auth UIDs; add verified `userId` links before expecting their
   uploaded photos to appear beside their ladder entries.

## Resolved or documented

- Normal challenge range, placement hours and scheduling window are explicit.
- Same-day response and result cutoff rules are explicit.
- Normal and G.O.D. ranking outcomes are represented in the pure Dart
  calculator.
- Duplicate result protection and audit events exist in the local demo.
- G.O.D. creation is now exposed in the UI, but the challenge is still only
  local in-memory state and is not an official backend placement.
- The Alerts screen is an in-app local-history surface, not a Firebase Cloud
  Messaging implementation.
