# Development Setup

## Prerequisites

- Flutter 3.47.7 or a compatible newer Flutter SDK
- Dart 3.13.5 supplied by Flutter
- Android Studio or an Android SDK/emulator
- Git

Verify the environment:

```bash
flutter doctor
flutter --version
```

Resolve Android toolchain issues reported by `flutter doctor` before trying to
run the application.

## Local project

1. Clone the repository and enter its root.
2. Run `flutter pub get`.
3. List available targets with `flutter devices`.
4. Start an Android emulator or connect an approved development device.
5. Run `flutter run` or `flutter run -d <device-id>`.

The Android app is connected to the development Firebase project. Sign in with
an authorized project account or register a player account to use the app.
Firebase configuration is checked into this workspace; never copy private
credentials into the client or commit service-account files.

The app and Android launcher use the same canonical image at
`assets/brand/app_brand_mark.png`. Android's density-specific copies are in
`android/app/src/main/res/mipmap-*/`; keep them generated from the canonical
image so the home-screen icon matches the in-app logo.

### Windows: Kotlin cache errors when project and Pub cache are on different drives

If Android builds fail with `this and base files have different roots` or
`Could not close incremental caches`, put the Dart Pub cache on the same drive
as the project. For a project in `D:\mukladder`, open a PowerShell terminal and
run:

```powershell
$env:PUB_CACHE = 'D:\PubCache'
flutter pub get
flutter run -d <device-id>
```

Set `PUB_CACHE` to `D:\PubCache` in Windows user environment variables to keep
using that cache in new terminals. The Android Gradle configuration disables
parallel and incremental Kotlin compilation to avoid cache registration
failures on this setup; the first build may take longer.

## What to try

1. Open **Ladder** to view the Firestore ranking feed. The development
   collection currently starts with a 24-player Week 7 Day 5 seed.
2. The screen refreshes when ranking documents change in Firestore.
3. Open **Profile** to view the signed-in account. Authorized Admin and
   Treasurer accounts see their role-specific workspace links.

The seed is not recalculated by a trusted rules engine yet. The official rule
document and a trusted backend are required before game results can update
official positions.

## Local verification

Run these commands from the project root:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The generated debug APK is at
`build/app/outputs/flutter-apk/app-debug.apk`.

## Firebase configuration

Firebase is configured for the current development workspace. Use these steps
only when configuring another development environment or replacing the Firebase
project.

### What the project owner must do

1. Create or select a Firebase project in the Firebase Console. Use a
   development project first; do not use a production project for this MVP
   setup.
2. Register the Android application using the exact Android application ID
   from `android/app/build.gradle.kts` (or the project's current Gradle
   configuration). Do not guess this value.
3. Enable **Authentication > Sign-in method > Email/Password**.
4. Create a Firestore database in development mode only. The initial rules
   must be replaced before real participant data is used.
5. Install or make available the Firebase CLI and FlutterFire CLI on the
   development machine.
6. From the repository root, run `flutterfire configure`, select the
   development project and Android platform, and allow it to generate the
   Flutter configuration file.
7. Return the generated project ID and confirm that configuration completed.
   Do not send passwords, service-account keys, private keys or `.env` files.

### What the implementation now does

- Uses Firebase Auth, Firestore and Firebase Messaging.
- Initializes Firebase before the application starts.
- Provides registration, login, logout and session restoration.
- Routes newly registered players to the player dashboard with the Join Ladder
  workflow. Admin and Treasurer access remains owner-assigned in the trusted
  user profile; there is no shared Admin key in the app.
- Lets players request to join, submit an external MTN MoMo reference after
  payment, and waits for Admin verification of the UGX 40,000 fee and initial
  ladder position.
- Updates each signed-in player's last-activity timestamp using Firestore
  server time on sign-in, app resume and a five-minute foreground heartbeat.
- Uses Firestore repositories for ranking, challenges, results, audit reads and
  notification history.
- Lets any signed-in player view ladder standings through the authenticated
  `getPublicLadder` callable, including before Admin membership approval. The
  callable returns only public ranking and player fields; private payment and
  account data remain protected by Firestore Rules.
- Uploads optional JPEG profile photos to Firebase Storage during registration
  and lets players replace them from their Profile.
- Protects client access with the checked-in Firestore Security Rules.
- Requests notification permission and registers foreground/background FCM
  handlers.

#### Signup troubleshooting

The signup screen reports Firebase's specific error instead of showing only a
generic authentication failure:

- If it says Email/Password sign-up is not enabled, open
  **Firebase Console > Authentication > Sign-in method** for
  `mukladder-4351c` and enable **Email/Password**.
- If the error includes `CONFIGURATION_NOT_FOUND`, open **Firebase Console >
  Authentication** for `mukladder-4351c`, finish setting up Authentication,
  enable **Email/Password** under **Sign-in method**, and confirm the Android
  app is registered in that same Firebase project.
- If it says Firestore denied saving the profile, publish the repository's
  current rules to that same project with
  `firebase deploy --only firestore:rules --project mukladder-4351c`.
  Authentication may already have created the account. Do not register that
  email again; sign in with it after the rules are published. Sign-in retries
  creation of a missing, least-privileged player profile.
- For any other failure, use the displayed Firebase error code to diagnose the
  configuration. Never share passwords or verification codes.

The registration approval transaction runs in a Firebase Callable Function.
It checks the Admin role from Firestore, verifies the payment confirmation,
assigns the initial position, and writes the approval audit event. All Admin
accounts must be assigned their role through a trusted, owner-controlled
process; never grant a role from the app. Emulator-test and deploy both
`firestore.rules` and `functions/` before using this workflow with real
participants. The Admin workspace also reads all player point totals and can
award positive whole-number manual points with a required reason. The
`addPlayerPoints` function records an idempotent point event and audit record;
these totals do not change ladder positions. Official match-result ranking
transitions still require confirmed scoring rules and their own trusted backend
workflow.

### Ladder membership requests and MTN MoMo

Newly registered players are not automatically placed in the Admin approval
queue. They use **Join Ladder** to create a membership request; each account
with the Admin role receives a persistent in-app alert. The player must obtain
the current UGX 40,000 MTN MoMo payment instructions from the authorized
Ladder Admin/Treasurer, pay outside the app, and submit the transaction
reference. That submission creates a second Admin alert but is only a payment
claim. The Admin must independently verify the reference in MTN MoMo before
confirming payment and approving the player.

The MTN MoMo merchant account is not configured in this project. The current
app does not initiate charges or validate settlement automatically. Do not
send money to a number displayed in an unverified message. Real in-app
collection requires an approved merchant account and a trusted server-side
MTN MoMo integration/callback; never put merchant secrets in the Flutter app.
The current membership alerts are stored in Firestore and shown live in the
Admin workspace; they are not push notifications when the Admin is offline.

From the repository root, after selecting the intended Firebase project, deploy
the approval function and Firestore rules with:

```powershell
firebase deploy --only functions,firestore:rules
```

Confirm the Functions runtime and any billing requirements in the Firebase
Console before deployment. Do not deploy to production until the approval
transaction and rules have passed Emulator Suite tests.

### Firebase Storage for profile photos

The app is currently configured for Firebase project `mukladder-4351c` and
bucket `mukladder-4351c.firebasestorage.app`. Before photo uploads can work:

1. In Firebase Console, confirm or create the project's Storage bucket and
   check that its bucket name exactly matches `lib/firebase_options.dart` and
   `android/app/google-services.json`.
2. Review `storage.rules`. Authenticated users can view profile photos; each
   user can upload or replace only their own JPEG (up to 5 MB).
3. If Firebase asks to enable billing or upgrade the plan, stop and confirm the
   project's budget before proceeding.
4. After approval, deploy the reviewed rules with `firebase deploy --only
   storage`.
5. Link existing ladder roster player documents to their account by setting
   the correct `userId`; do not match accounts using display names alone.

If upload reports `object-not-found`, verify the bucket exists and the app is
configured for that exact bucket. `putData` must complete before the app asks
Storage for the download URL. If upload reports `unauthorized`, deploy the
reviewed Storage rules. The photo's bytes are stored in Storage; Firestore
stores its download URL and Storage path on both the user and player profile.

Firebase download URLs contain access tokens and should be treated as
shareable links: anyone who obtains a URL may be able to view that image.
Players should upload only photos they are comfortable displaying to other
ladder users and with that link-access behavior.

No Storage bucket was created and no rules were deployed as part of this code
change.

The Profile screen also shows the player's submitted match scores with their
opponents and result states. The app does not calculate official ladder points
from those scores.

### Required configuration artifacts

The FlutterFire-generated `lib/firebase_options.dart` and Android Firebase
configuration are project configuration, not credentials. They may be
committed when generated for this repository, subject to the team's repository
policy. Service-account JSON files, private keys, passwords, `.env` files and
admin credentials must never be committed.

Firebase configuration is now present for the Android development project.
The app initializes Firebase at startup and includes email/password
registration, login, logout and session restoration.

To deploy the checked-in Firestore rules after reviewing them:

```bash
firebase use mukladder
firebase deploy --only firestore:rules
```

Do not deploy rules to a production project without explicit approval.

Never commit service-account keys, private keys, passwords, `.env` files or
production credentials. Do not enable billing or make destructive production
changes without explicit approval.

## Troubleshooting

If dependencies are stale, run `flutter pub get`. If the Android toolchain is
not detected, run `flutter doctor` and resolve only the relevant missing
component. If multiple devices are connected, pass a device ID to
`flutter run -d`. Record environment-specific blockers in
`docs/PROGRESS.md`.
