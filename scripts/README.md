# Emulator test scripts

## Start the Firebase Emulator Suite

```bash
cd /Users/ios/Documents/Ladder/mukladder
firebase emulators:start --project mukladder-4351c
```

UI: http://127.0.0.1:4000

Ports:
- Auth `9099`
- Firestore `8080`
- Functions `5001`
- Storage `9199`

## Seed sign-in users (recommended)

With emulators running:

```bash
node scripts/create-test-users.js
```

Creates Auth + Firestore users:

| Role | Email | Password |
|---|---|---|
| Admin | `admin@mukladder.test` | `admin123` |
| Treasurer | `treasurer@mukladder.test` | `treasurer123` |
| Player 1 | `player1@mukladder.test` | `player123` |
| Player 2 | `player2@mukladder.test` | `player123` |
| Player 3 | `player3@mukladder.test` | `player123` |
| Player 4 | `player4@mukladder.test` | `player123` |
| Pending | `pending@mukladder.test` | `player123` |

## Optional Firestore-only seed

```bash
node scripts/add-test-data.js
```

## Flutter app

`lib/emulator_config.dart` has `useEmulator = true` and points Android
emulator traffic at `10.0.2.2` (your Mac). Rebuild/restart the app after
changing that flag.

Physical phone: change `EmulatorConfig.host` to your Mac LAN IP.

When done with local testing, set `useEmulator = false` again.
