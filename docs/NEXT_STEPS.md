# Next Steps

## Current state — 11 November 2026

Trusted match-result confirmation now updates rankings on the server. The
remaining work is deployment, smoke testing and submission polish — not new
core features.

## 1. Deploy and smoke-test the ranking path (highest priority)

- Deploy Cloud Functions (`confirmMatchResult`, membership/points functions,
  `applyInactivityDrops`) and updated `firestore.rules` to `mukladder-4351c`.
- On two Android accounts: place Normal challenge → accept → submit score →
  opponent confirms → verify ladder positions, winner cooldown stamp, audit
  event and in-app notifications.
- Confirm disputed scores still work and do **not** change rankings.

## 2. Confirm remaining rule ambiguities with Ladder Admin / lecturer

- Obtain the MUK Ladder Rules, 2025 source document.
- Confirm 2026/2027 applicability of placement windows, G.O.D. consequences and
  Rule 10 inactivity (currently provisional: one drop per seven days).
- Confirm Admin vs Treasurer override duties for disputed results and walkovers.

## 3. Stabilisation for the 26 November submission

- Tag a release-candidate build once the smoke test passes.
- Write / rehearse the demo script: join → approve → challenge → result →
  rank change → admin overview.
- Finish report draft, architecture diagram and peer-evaluation forms.
- Do **not** start stretch goals (court booking, SMS, payment gateway).

## 4. Optional hardening if time remains

- Emulator Suite tests for `confirmMatchResult` authorization and idempotency.
- Scheduled enforcement of the 8 p.m. result cutoff.
- FCM push for result-confirmed / cooldown-ended events (in-app notifications
  already written on confirm).
- Extract large screens from `lib/app/app.dart` into feature presentation files.

## Registration / membership notes (unchanged)

- New accounts start without a join request. Admin verifies the UGX 40,000 fee
  after an external payment reference, then assigns an initial position.
- The app does not collect or automatically validate money.
- Firebase CLI deploy and production credential steps remain owner actions.
