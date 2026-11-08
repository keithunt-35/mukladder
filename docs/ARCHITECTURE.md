# MUKLadder Architecture

## Status

This document describes the implemented Flutter/Firebase baseline and the
remaining trusted-backend work.

## Client structure

Organize `lib/` by feature, with these responsibilities:

- `app/`: application shell, theme and navigation.
- `core/`: shared errors, utilities and reusable widgets.
- `features/<feature>/presentation/`: screens and widgets.
- `features/<feature>/application/`: workflows and state providers.
- `features/<feature>/domain/`: models, validation and pure business rules.
- `features/<feature>/data/`: repositories, Firestore access and mapping.

The app uses Riverpod for state access and `go_router` for declarative
navigation. The main shell exposes the ladder, profile, challenges and alerts;
Admin and Treasurer workspaces are role-guarded.

The in-app logo and Android launcher icon use the shared
`assets/brand/app_brand_mark.png` source; Android density-specific launcher
images are resized copies of that asset.

Expected feature areas are auth, players, ladder, challenges, results,
notifications, admin and treasurer. Do not create empty structure without a
feature need.

## Data flow

The UI invokes application workflows and repositories map Firebase data to
domain models. The ladder subscribes to Firestore `rankings` snapshots, which
allows the UI to reflect server updates without a hardcoded in-app player list.
The current 24-player development seed is still a static starting dataset.
Trusted backend workflows for match-result ranking and other tournament
operations are still incomplete; do not present local calculations as
official.

New player accounts start outside the ladder. A trusted callable function
creates the join request and persistent Admin notifications. After paying
externally, a player submits an MTN MoMo reference; this is only a claim.
`approvePlayerRegistration` requires the reference to be reported, checks the
caller's Admin role, and atomically records Admin-verified payment, inserts
the initial position, activates membership and writes audit/notification
records. The merchant account is not configured and the app does not charge or
verify payments automatically. Client Firestore rules continue to deny
ranking writes. App activity uses server timestamps on sign-in, resume and a
five-minute foreground heartbeat; the ladder listens for those player
document changes.

## Backend responsibilities

- Firebase Auth authenticates users.
- Firestore stores player profiles (including photo download URLs), challenge,
  result, ranking, notification and audit data.
- Firebase Storage holds JPEG profile photos at
  `profilePhotos/{uid}/profile.jpg`. Storage rules restrict uploads and
  replacements to that authenticated owner and allow signed-in players to view
  ladder photos.
- Cloud Functions are the authority for join/payment reports, registration
  approval, manual points and initial ranking placement. Match-result ranking
  changes, deadline handling,
  cooldowns, inactivity penalties and notifications remain outstanding.
- Firestore Security Rules enforce authentication, ownership and role
  boundaries.
- Scheduled operations must be idempotent and safe to retry.

## Authentication and authorization

Authentication uses Firebase Auth. App roles are loaded from the user's
Firestore profile and the UI checks roles separately for Admin and Treasurer
screens. Backend rules remain the security boundary; a client-side role check
is not sufficient authorization.

Sign-up optionally selects a photo from the device gallery, resizes it to a
maximum 512-by-512 image and uploads it to the authenticated user's Storage
path. The resulting download URL and Storage path are recorded in the Firestore
user profile and player document; image bytes belong in Storage, not a
Firestore document.
Existing players can change their photo from Profile. The ladder merges ordered
ranking documents with player documents and refreshes when either collection
changes. Existing seeded players must have a matching player document linked to
their Auth UID (`userId`) before their uploaded photo is associated with that
ranking entry.

Player signups use a pending-registration status and open the player dashboard
immediately. Pending players can request membership and report payment there;
the member directory, rankings and other player features remain restricted
until an Admin approves registration. The profile stream reflects approval
immediately after the Cloud Function updates the user document. Admin and
Treasurer roles remain owner-assigned in Firebase; the client does not accept a
shared role-granting key.
Each first join request creates a persistent in-app notification for every
configured Admin, containing the player's identity and a prompt to review the
request in the Admin workspace. Duplicate requests do not create duplicate
alerts.

The Profile match history reads the signed-in user's challenges, fetches the
associated result records and resolves opponent names from player documents.
It displays the reported match score and confirmation state. No authoritative
ladder-point total is calculated because the trusted ranking workflow and
confirmed 2026 scoring rules are not implemented.

## Offline strategy

Start with Firestore-supported offline persistence for previously synchronized
read data. The UI must distinguish synchronized data, potentially stale cache,
pending writes and rejected writes. Deadline-sensitive challenges and results
must be revalidated by the server before they become official. A separate local
database is not approved unless testing shows the built-in cache is
insufficient.

## Rule engine

Ranking and challenge rules belong in pure Dart functions/classes with explicit
inputs and outputs. The existing ranking calculator is explicitly provisional
and only supports local demonstration logic. Verify the complete official
rulebook before implementing authoritative game outcomes. Ranking writes must
be performed by a trusted server transaction.
