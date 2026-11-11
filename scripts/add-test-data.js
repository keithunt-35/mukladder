/**
 * Seed Firestore-only demo ladder rows into the Firebase Emulator.
 * Prefer scripts/create-test-users.js when you also need Auth logins.
 *
 * Run: node scripts/add-test-data.js
 */

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const { createRequire } = require('node:module');
const path = require('node:path');
const requireFromFunctions = createRequire(
  path.join(__dirname, '..', 'functions', 'package.json'),
);

const { initializeApp } = requireFromFunctions('firebase-admin/app');
const { FieldValue, getFirestore } = requireFromFunctions(
  'firebase-admin/firestore',
);

initializeApp({ projectId: 'mukladder-4351c' });
const db = getFirestore();

async function addTestData() {
  console.log('Adding Firestore test data to Firebase Emulator...\n');

  const testPlayers = [
    { name: 'Tayebwa Louis', email: 'tayebwa@test.com', position: 1 },
    { name: 'Ahimbisibwe Kevin', email: 'ahimbisibwe@test.com', position: 2 },
    { name: 'Wanale Fredrick', email: 'wanale@test.com', position: 3 },
    { name: 'Kato John', email: 'kato@test.com', position: 4 },
    { name: 'Mugabi Sarah', email: 'mugabi@test.com', position: 5 },
    { name: 'Nabwama Alice', email: 'nabwama@test.com', position: 6 },
  ];

  for (const player of testPlayers) {
    const userId = `player-${player.position}`;

    await db.collection('users').doc(userId).set({
      uid: userId,
      email: player.email,
      displayName: player.name,
      role: 'player',
      status: 'active',
      registrationStatus: 'approved',
      joinRequestStatus: 'approved',
      paymentStatus: 'paid',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await db.collection('players').doc(userId).set({
      userId,
      displayName: player.name,
      joinRequestStatus: 'approved',
      paymentStatus: 'paid',
      registrationStatus: 'approved',
      active: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await db.collection('rankings').doc(userId).set({
      playerId: userId,
      position: player.position,
      effectiveAt: FieldValue.serverTimestamp(),
      sourceResultId: null,
      version: 1,
    });

    console.log(`✓ ${player.name} at position ${player.position}`);
  }

  await db.collection('system').doc('ladderState').set(
    {
      revision: 0,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log('\n✅ Firestore seed complete.');
  console.log('For sign-in accounts, also run: node scripts/create-test-users.js');
}

addTestData().catch((error) => {
  console.error('❌ Error adding test data:', error);
  process.exit(1);
});
