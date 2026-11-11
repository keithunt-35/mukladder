/**
 * Create Auth users + Firestore profiles in the Firebase Emulator.
 *
 * Prerequisites:
 *   firebase emulators:start --project mukladder-4351c
 *
 * Run:
 *   node scripts/create-test-users.js
 */

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';

const { createRequire } = require('node:module');
const path = require('node:path');
const requireFromFunctions = createRequire(
  path.join(__dirname, '..', 'functions', 'package.json'),
);

const { initializeApp } = requireFromFunctions('firebase-admin/app');
const { getAuth } = requireFromFunctions('firebase-admin/auth');
const { FieldValue, getFirestore } = requireFromFunctions(
  'firebase-admin/firestore',
);

const projectId = 'mukladder-4351c';

initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();

const testUsers = [
  {
    email: 'admin@mukladder.test',
    password: 'admin123',
    displayName: 'Ladder Admin',
    role: 'admin',
    registrationStatus: 'approved',
    joinRequestStatus: 'approved',
    paymentStatus: 'paid',
    ladderPosition: null,
  },
  {
    email: 'treasurer@mukladder.test',
    password: 'treasurer123',
    displayName: 'Treasurer',
    role: 'treasurer',
    registrationStatus: 'approved',
    joinRequestStatus: 'approved',
    paymentStatus: 'paid',
    ladderPosition: null,
  },
  {
    email: 'player1@mukladder.test',
    password: 'player123',
    displayName: 'Player One',
    role: 'player',
    registrationStatus: 'approved',
    joinRequestStatus: 'approved',
    paymentStatus: 'paid',
    ladderPosition: 1,
  },
  {
    email: 'player2@mukladder.test',
    password: 'player123',
    displayName: 'Player Two',
    role: 'player',
    registrationStatus: 'approved',
    joinRequestStatus: 'approved',
    paymentStatus: 'paid',
    ladderPosition: 2,
  },
  {
    email: 'player3@mukladder.test',
    password: 'player123',
    displayName: 'Player Three',
    role: 'player',
    registrationStatus: 'approved',
    joinRequestStatus: 'approved',
    paymentStatus: 'paid',
    ladderPosition: 3,
  },
  {
    email: 'player4@mukladder.test',
    password: 'player123',
    displayName: 'Player Four',
    role: 'player',
    registrationStatus: 'approved',
    joinRequestStatus: 'approved',
    paymentStatus: 'paid',
    ladderPosition: 4,
  },
  {
    email: 'pending@mukladder.test',
    password: 'player123',
    displayName: 'Pending Player',
    role: 'player',
    registrationStatus: 'pending',
    joinRequestStatus: 'requested',
    paymentStatus: 'pending',
    ladderPosition: null,
  },
];

async function upsertUser(userData) {
  let userRecord;
  try {
    userRecord = await auth.createUser({
      email: userData.email,
      password: userData.password,
      displayName: userData.displayName,
    });
    console.log(`Created Auth user: ${userData.email} (${userRecord.uid})`);
  } catch (error) {
    if (error.code !== 'auth/email-already-exists') {
      throw error;
    }
    userRecord = await auth.getUserByEmail(userData.email);
    console.log(`Auth user exists: ${userData.email} (${userRecord.uid})`);
  }

  const approved = userData.registrationStatus === 'approved';
  await db.collection('users').doc(userRecord.uid).set(
    {
      uid: userRecord.uid,
      email: userData.email,
      displayName: userData.displayName,
      role: userData.role,
      status: 'active',
      registrationStatus: userData.registrationStatus,
      joinRequestStatus: userData.joinRequestStatus,
      paymentStatus: userData.paymentStatus,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await db.collection('players').doc(userRecord.uid).set(
    {
      userId: userRecord.uid,
      displayName: userData.displayName,
      registrationStatus: userData.registrationStatus,
      joinRequestStatus: userData.joinRequestStatus,
      paymentStatus: userData.paymentStatus,
      active: approved && userData.role === 'player',
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  if (
    approved &&
    userData.role === 'player' &&
    Number.isInteger(userData.ladderPosition)
  ) {
    await db.collection('rankings').doc(userRecord.uid).set({
      playerId: userRecord.uid,
      position: userData.ladderPosition,
      effectiveAt: FieldValue.serverTimestamp(),
      sourceResultId: null,
      version: 1,
    });
    console.log(
      `Ranked ${userData.email} at position ${userData.ladderPosition}`,
    );
  }
}

async function main() {
  console.log(`Seeding emulator project ${projectId}...\n`);
  await db.collection('system').doc('ladderState').set(
    {
      revision: 0,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  for (const userData of testUsers) {
    await upsertUser(userData);
  }

  console.log('\n✅ Emulator users ready. Sign in with:');
  for (const userData of testUsers) {
    console.log(
      `  ${userData.role.padEnd(10)} ${userData.email} / ${userData.password}`,
    );
  }
  console.log('\nEmulator UI: http://127.0.0.1:4000');
}

main().catch((error) => {
  console.error('❌ Seed failed:', error);
  process.exit(1);
});
