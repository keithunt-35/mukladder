# Data Model

This is the MVP domain model and Firestore model. The development project
contains the initial 24-player and ranking snapshot. Field names and
rule-sensitive constraints must still be finalized before production use.
Firestore ranking reads are ordered by position and the app listens for live
document changes; the seeded ranking is not automatically recalculated after
game results.

## Implemented pure Dart models

- `Player`: identity, display name, optional profile photo URL, activity
  timestamp, payment-status flag and active state.
- `RankingEntry`: a player and a positive ladder position.
- `Challenge`: participants, type, status and creation/proposed-date metadata.
  It rejects invalid state transitions.
- `MatchResult`: challenge reference, submitting player, score, status and
  submission time. It rejects invalid state transitions.
- Confirming a result completes its accepted challenge in the local workflow;
  disputed results remain available for review.
- Result submission and status transitions create immutable in-memory audit
  events. The production implementation must write equivalent events in a
  trusted backend transaction.

Firestore repositories are used by the connected app. In-memory repositories
remain for isolated tests and local domain demonstrations; they are not
authoritative tournament data.

The current demo result repository accepts a provisional comma-separated score
format such as `6-4, 6-3`, only for accepted challenges and their participants.
The client-side workflow is not a trusted backend rule implementation. The
official scoring and deadline policy must be verified before production use.

## Firestore collections

### `users/{uid}`

`uid`, `displayName`, `email`, `photoUrl`, `photoStoragePath`, `role`,
`status`, `registrationStatus`, `joinRequestStatus`, `paymentStatus`,
`paymentReference`, `joinRequestedAt`, `paymentReportedAt`, `lastActivityAt`,
`approvedBy`, `approvedAt`, `createdAt`, `updatedAt`.
The role is written only by an authorized backend/admin workflow.
New player documents start at `registrationStatus: notRequested` and
`joinRequestStatus: notRequested`. Requesting to join sets status to pending
and sends Admin notifications. After paying externally, the player submits an
MTN MoMo transaction reference; this is a claim only, not payment
confirmation. Admins must verify it externally before approval marks payment
paid and membership approved.

### `players/{playerId}`

`userId`, `displayName`, `position`, `lastActivityAt`, `registrationStatus`,
`joinRequestStatus`, `paymentStatus`, `paymentReference`, `photoUrl`, `active`,
`createdAt`, `updatedAt`.
The app also stores `photoStoragePath` on linked profile documents.

Profile photos are stored in Firebase Storage at
`profilePhotos/{uid}/profile.jpg`. The matching download URL is copied to the
user profile and linked player document. New registrations begin with a
pending, inactive player document. The Admin approval transaction assigns the
manually selected initial position and shifts later positions; it rejects
existing gaps or duplicate positions. Server timestamps record last activity
when the app opens, resumes and remains foregrounded.

The Profile match history joins the signed-in player's challenge records with
their `results` documents and the opponent's public player profile. The score
shown is the submitted score string, with its result status and date. It is not
a ladder-points calculation; authoritative points and ranking changes require
confirmed scoring rules and a trusted backend.

### `challenges/{challengeId}`

`challengerId`, `challengedId`, `type`, `status`, `proposedAt`,
`responseDeadline`, `proposedDate`, `alternativeDate`, `consent`,
`createdAt`, `updatedAt`.

### `results/{resultId}`

`challengeId`, `submittedBy`, `score`, `status`, `submittedAt`,
`confirmedAt`, `disputedAt`, `reviewedBy`, `reviewedAt`.

### `rankings/{rankingId}`

`playerId`, `position`, `effectiveAt`, `sourceResultId`, `version`.
Official ranking mutations are backend-only and should use a transaction or
equivalent concurrency-safe operation.

Signed-in players can view ladder standings before membership approval through
the authenticated `getPublicLadder` callable. It joins ranking documents to
player records on the server and returns only `playerId`, `position`,
`displayName`, `photoUrl`, `lastActivityAt` and `active`. It must not return
payment references, payment status, email addresses or other private fields.
Direct Firestore ranking and player reads remain subject to the existing
Security Rules; pending clients do not receive the full player documents.

### `playerPoints/{playerId}` and `playerPointEvents/{requestId}`

`playerPoints` stores `playerId`, `totalPoints`, `createdAt`, `updatedAt` and
`updatedBy`. It is an Admin-readable, client-read-only total. The callable
`addPlayerPoints` accepts positive whole-number awards with a required reason,
updates the total transactionally and appends an immutable event and audit
record. Request IDs make retries idempotent. These manual points do not change
ladder positions; point scoring from match outcomes remains unimplemented
until the official rules are confirmed.

### `auditEvents/{eventId}`

`actorId`, `actorRole`, `eventType`, `entityType`, `entityId`, `before`,
`after`, `reason`, `createdAt`.

### `notifications/{notificationId}`

`recipientId`, `type`, `title`, `body`, `readAt`, `createdAt`.

## Relationships and validation

Users and players are linked by `userId`. A challenge references two players
and may produce one result. A confirmed result may produce a ranking event.
Identifiers must be generated by trusted services where the operation affects
official state. Validate ownership, allowed enum values, timestamps, score
shape, participant identity and state transitions.

Payment information is represented only as a status flag; do not store payment
credentials. Security Rules must prevent unauthorized reads and writes, and
backend validation must not rely on client-provided role or ranking fields.
