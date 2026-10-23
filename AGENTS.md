# MUKLadder Agent Instructions

## Purpose

MUKLadder is a Flutter Android-first application for managing the Makerere
University Tennis Ladder. It supports players, Ladder Admins and Treasurers
while preserving the official ladder rules and an auditable ranking history.

## Before coding

Read [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md),
[docs/PROGRESS.md](docs/PROGRESS.md), [docs/NEXT_STEPS.md](docs/NEXT_STEPS.md),
and the relevant architecture, data-model and rules documents. Read
[docs/MASTER_PROMPT.md](docs/MASTER_PROMPT.md) for the full working agreement.
Inspect the actual code and Git status; do not assume the documentation is
current.

## Architecture and decisions

Use Flutter/Dart with a simple feature-oriented structure. Keep presentation,
state/application workflows, domain rules and data access separate. Firebase
will provide authentication, Firestore, trusted Cloud Functions and FCM.
Firestore offline persistence is preferred initially; add a local database only
if it is proven necessary. The server is authoritative for rankings, deadlines,
roles and other rule-sensitive mutations.

Technical choices that are not yet approved must be recorded in
[docs/DECISIONS.md](docs/DECISIONS.md) before they become dependencies.

## Quality and safety

- Make small, complete, testable changes.
- Run formatting, `flutter analyze` and relevant tests for code changes.
- Keep ranking logic in pure Dart and test it independently of Firebase/UI.
- Never invent or silently interpret an official rule; record ambiguities and
  request clarification.
- Never trust client-supplied roles or allow direct client ranking mutations.
- Never commit credentials, service-account keys, `.env` secrets or generated
  Firebase configuration containing secrets.
- Preserve unrelated user changes and never rewrite history or force-push.
- Update project memory, especially `docs/PROGRESS.md` and
  `docs/NEXT_STEPS.md`, after every completed task.

