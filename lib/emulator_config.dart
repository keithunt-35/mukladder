// Emulator configuration for local development
// Set useEmulator to true to connect to Firebase Emulator Suite

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class EmulatorConfig {
  static const bool useEmulator = false;
  static const String host = '10.0.2.2'; // Android emulator host
  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int storagePort = 9199;
}

Future<void> setupEmulators() async {
  if (!EmulatorConfig.useEmulator) {
    return;
  }

  try {
    // Connect to Firestore emulator
    FirebaseFirestore.instance.useFirestoreEmulator(
      EmulatorConfig.host,
      EmulatorConfig.firestorePort,
    );

    // Connect to Auth emulator
    FirebaseAuth.instance.useAuthEmulator(
      EmulatorConfig.host,
      EmulatorConfig.authPort,
    );

    if (kDebugMode) {
      print('Firebase Emulators connected:');
      print('  Firestore: ${EmulatorConfig.host}:${EmulatorConfig.firestorePort}');
      print('  Auth: ${EmulatorConfig.host}:${EmulatorConfig.authPort}');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error setting up emulators: $error');
    }
  }
}
