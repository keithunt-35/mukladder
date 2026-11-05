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

Expected feature areas are auth, players, ladder, challenges, results,
notifications, admin and treasurer. Do not create empty structure without a
feature need.

## Data flow

The UI invokes application workflows and repositories map Firebase data to
domain models. The ladder subscribes to Firestore `rankings` snapshots, which
allows the UI to reflect server updates without a hardcoded in-app player list.
The current 24-player development seed is still a static starting dataset.
Trusted backend functions for rule-sensitive ranking and administrative
mutations have not yet been implemented; do not present local calculations as
official.

## Backend responsibilities

- Firebase Auth authenticates users.
- Firestore stores player profiles (including photo download URLs), challenge,
  result, ranking, notification and audit data.
- Firebase Storage holds JPEG profile photos at
  `profilePhotos/{uid}/profile.jpg`. Storage rules restrict uploads and
  replacements to that authenticated owner and allow signed-in players to view
  ladder photos.
- Cloud Functions are the planned authority for privileged ranking changes,
  deadline handling, cooldowns, inactivity penalties and notifications; these
  workflows remain outstanding.
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
