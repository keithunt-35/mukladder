# Test Data Scripts

## Overview

This directory contains scripts to populate the Firebase Emulator with test data.

## Prerequisites

1. **Firebase Emulator running:**
   ```bash
   cd /Users/ios/Documents/Ladder/mukladder
   firebase emulators:start --project mukladder
   ```

2. **Node.js installed:**
   ```bash
   node --version  # Should be 16 or higher
   ```

3. **Firebase Admin SDK installed:**
   ```bash
   cd functions
   npm install firebase-admin
   cd ..
   ```

## Available Scripts

### 1. add-test-data.js

Adds test players, user profiles, and ranking entries to the emulator.

**Run:**
```bash
node scripts/add-test-data.js
```

**What it does:**
- Creates 6 players with user profiles, player documents, and ranking entries
- Adds 2 pending registration users for testing join workflow
- Users have email: `{name}@test.com` and password: `test123`

**Output:**
```
Adding test data to Firebase Emulator...

Creating players and user profiles...

✓ Created user profile: Tayebwa Louis (tayebwa@test.com)
✓ Created player document: Tayebwa Louis
✓ Added to rankings at position 1

...

✅ Test data added successfully!
```

### 2. create-test-users.js (Advanced)

Creates users with specific roles (player, admin, treasurer) using Firebase Auth.

**Prerequisites:**
- Service account key for Firebase
- Set environment variables:
  ```bash
  export FIREBASE_CLIENT_EMAIL="your-service-account@project.iam.gserviceaccount.com"
  export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
  ```

**Run:**
```bash
node scripts/create-test-users.js
```

**What it does:**
- Creates users in Firebase Authentication
- Creates corresponding Firestore profiles
- Creates player documents
- Adds approved players to rankings

## Testing the App

After running the script:

1. **Open the app** on your device
2. **Login** with any of the test users
3. **Explore features:**
   - View the ladder
   - Submit challenges
   - Report results
   - Test admin workflow (if admin user)

## Resetting Data

To clear all data and start fresh:

```bash
firebase emulators:start --project mukladder --only firestore --inspect-firestore
```

Or manually delete in Emulator UI:
1. Go to http://localhost:4000
2. Click "Firestore Database"
3. Delete collections or documents as needed

## Production vs Emulator

⚠️ **Important:** These scripts only work with the Firebase Emulator.

For production, use the Firebase Console or deploy a secure backend function.
