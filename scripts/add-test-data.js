/**
 * Simple script to add test data to Firebase Emulator
 * Run: node scripts/add-test-data.js
 */

const { initializeApp, FieldValue } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Configure for emulator
const app = initializeApp({
  projectId: 'mukladder',
});

const db = getFirestore();

async function addTestData() {
  try {
    console.log('Adding test data to Firebase Emulator...\n');

    // Add players with their user profiles
    const testPlayers = [
      { name: 'Tayebwa Louis', email: 'tayebwa@test.com', position: 1 },
      { name: 'Ahimbisibwe Kevin', email: 'ahimbisibwe@test.com', position: 2 },
      { name: 'Wanale Fredrick', email: 'wanale@test.com', position: 3 },
      { name: 'Kato John', email: 'kato@test.com', position: 4 },
      { name: 'Mugabi Sarah', email: 'mugabi@test.com', position: 5 },
      { name: 'Nabwama Alice', email: 'nabwama@test.com', position: 6 },
    ];

    console.log('Creating players and user profiles...\n');

    for (const player of testPlayers) {
      const userId = `player-${player.position}`;

      // Create user profile
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

      console.log(`✓ Created user profile: ${player.name} (${player.email})`);

      // Create player document
      await db.collection('players').doc(userId).set({
        userId: userId,
        displayName: player.name,
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
        registrationStatus: 'approved',
        active: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(`✓ Created player document: ${player.name}`);

      // Create ranking entry
      await db.collection('rankings').doc(userId).set({
        playerId: userId,
        position: player.position,
        effectiveAt: FieldValue.serverTimestamp(),
        sourceResultId: null,
        version: 1,
      });

      console.log(`✓ Added to rankings at position ${player.position}\n`);
    }

    // Add some pending registrations (for testing join workflow)
    console.log('Adding pending registrations...\n');

    const pendingPlayers = [
      { name: 'Pending Player 1', email: 'pending1@test.com' },
      { name: 'Pending Player 2', email: 'pending2@test.com' },
    ];

    for (const player of pendingPlayers) {
      const userId = `pending-${Date.now()}`;

      // Create user profile
      await db.collection('users').doc(userId).set({
        uid: userId,
        email: player.email,
        displayName: player.name,
        role: 'player',
        status: 'active',
        registrationStatus: 'pending',
        joinRequestStatus: 'requested',
        paymentStatus: 'pending',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(`✓ Created pending user: ${player.name}`);

      // Create player document
      await db.collection('players').doc(userId).set({
        userId: userId,
        displayName: player.name,
        joinRequestStatus: 'requested',
        paymentStatus: 'pending',
        registrationStatus: 'pending',
        active: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(`✓ Created pending player: ${player.name}\n`);
    }

    console.log('\n✅ Test data added successfully!');
    console.log('\nYou can now login with:');
    console.log('  - Regular players: Any email/password (will be auto-approved on sign-up)');
    console.log('  - Pending players: pending1@test.com, pending2@test.com');
    console.log('\nTo test admin features:');
    console.log('  - Create an admin user manually in Firestore');
    console.log('  - Set role: "admin" in /users/{uid} document');

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error adding test data:', error);
    process.exit(1);
  }
}

addTestData();
