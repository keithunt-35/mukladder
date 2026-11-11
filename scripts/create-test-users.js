/**
 * Script to create test users in Firebase Emulator
 * 
 * Run: node scripts/create-test-users.js
 * 
 * Prerequisites:
 * - Firebase Emulator must be running: firebase emulators:start
 * - This script uses the emulator's ports (localhost:8080 for Firestore)
 */

const admin = require('firebase-admin');

// Emulator configuration
const emulatorHost = 'localhost';
const emulatorFirestorePort = 8080;
const emulatorAuthPort = 9099;

async function main() {
  try {
    // Initialize Admin SDK for emulator
    const serviceAccount = {
      projectId: 'mukladder',
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY,
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: 'mukladder',
      host: emulatorHost,
      port: emulatorFirestorePort,
    });

    const db = admin.firestore();
    const auth = admin.auth();

    // Test user data
    const testUsers = [
      // Admin user
      {
        email: 'admin@mukladder.test',
        password: 'admin123',
        displayName: 'Ladder Admin',
        role: 'admin',
        status: 'active',
        registrationStatus: 'approved',
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
      },
      // Treasurer user
      {
        email: 'treasurer@mukladder.test',
        password: 'treasurer123',
        displayName: 'Treasurer',
        role: 'treasurer',
        status: 'active',
        registrationStatus: 'approved',
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
      },
      // Player users
      {
        email: 'player1@mukladder.test',
        password: 'player123',
        displayName: 'Player One',
        role: 'player',
        status: 'active',
        registrationStatus: 'approved',
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
      },
      {
        email: 'player2@mukladder.test',
        password: 'player123',
        displayName: 'Player Two',
        role: 'player',
        status: 'active',
        registrationStatus: 'approved',
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
      },
      {
        email: 'player3@mukladder.test',
        password: 'player123',
        displayName: 'Player Three',
        role: 'player',
        status: 'active',
        registrationStatus: 'approved',
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
      },
      // Pending registration user (for testing join workflow)
      {
        email: 'pending@mukladder.test',
        password: 'player123',
        displayName: 'Pending Player',
        role: 'player',
        status: 'active',
        registrationStatus: 'pending',
        joinRequestStatus: 'requested',
        paymentStatus: 'pending',
      },
    ];

    console.log('Creating test users...');

    for (const userData of testUsers) {
      try {
        // Create Auth user
        const userRecord = await auth.createUser({
          email: userData.email,
          password: userData.password,
          displayName: userData.displayName,
        });

        console.log(`Created Auth user: ${userData.email} (UID: ${userRecord.uid})`);

        // Create Firestore user profile
        await db.collection('users').doc(userRecord.uid).set({
          uid: userRecord.uid,
          email: userData.email,
          displayName: userData.displayName,
          role: userData.role,
          status: userData.status,
          registrationStatus: userData.registrationStatus,
          joinRequestStatus: userData.joinRequestStatus,
          paymentStatus: userData.paymentStatus,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Created Firestore profile for ${userData.email}`);

        // Create player document
        await db.collection('players').doc(userRecord.uid).set({
          userId: userRecord.uid,
          displayName: userData.displayName,
          joinRequestStatus: userData.joinRequestStatus,
          paymentStatus: userData.paymentStatus,
          registrationStatus: userData.registrationStatus,
          active: userData.registrationStatus === 'approved',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Created player document for ${userData.email}`);

        // Add to rankings if approved
        if (userData.registrationStatus === 'approved' && userData.role === 'player') {
          const position = testUsers.indexOf(userData) + 2; // Admin and Treasurer have positions 1 and 2
          await db.collection('rankings').doc(userRecord.uid).set({
            playerId: userRecord.uid,
            position: position,
            effectiveAt: admin.firestore.FieldValue.serverTimestamp(),
            sourceResultId: null,
            version: 1,
          });

          console.log(`Added ${userData.email} to rankings at position ${position}`);
        }

        console.log('---');
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          console.log(`User ${userData.email} already exists, updating profile...`);

          // Find existing user by email
          const existingUser = await auth.getUserByEmail(userData.email);
          
          // Update Firestore profile
          await db.collection('users').doc(existingUser.uid).set({
            role: userData.role,
            registrationStatus: userData.registrationStatus,
            joinRequestStatus: userData.joinRequestStatus,
            paymentStatus: userData.paymentStatus,
          }, { merge: true });

          console.log(`Updated profile for ${userData.email} (UID: ${existingUser.uid})`);
        } else {
          console.error(`Error creating user ${userData.email}:`, error.message);
        }
      }
    }

    console.log('\nTest users created successfully!');
    console.log('\nLogin credentials:');
    for (const userData of testUsers) {
      console.log(`  ${userData.role.toUpperCase()}: ${userData.email} / ${userData.password}`);
    }

    process.exit(0);
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

main();
