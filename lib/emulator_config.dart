// Emulator configuration for local development.
// Set useEmulator to true to connect to the Firebase Emulator Suite.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform, TargetPlatform;

class EmulatorConfig {
  /// Flip to true for local Auth / Firestore / Functions / Storage emulators.
  static const bool useEmulator = true;

  /// Android emulator → host machine loopback.
  /// Physical device → replace with your Mac LAN IP (e.g. 192.168.x.x).
  static const String host = '10.0.2.2';

  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int functionsPort = 5001;
  static const int storagePort = 9199;
}

Future<void> setupEmulators() async {
  if (!EmulatorConfig.useEmulator) {
    return;
  }

  // Only wire emulators from a debug Android build.
  if (!kDebugMode || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  try {
    FirebaseFirestore.instance.useFirestoreEmulator(
      EmulatorConfig.host,
      EmulatorConfig.firestorePort,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      EmulatorConfig.host,
      EmulatorConfig.authPort,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(
      EmulatorConfig.host,
      EmulatorConfig.functionsPort,
    );
    FirebaseStorage.instance.useStorageEmulator(
      EmulatorConfig.host,
      EmulatorConfig.storagePort,
    );

    // Clear persistence so cached production data cannot leak into emulator runs.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase Emulators connected at ${EmulatorConfig.host}:');
      // ignore: avoid_print
      print('  Auth ${EmulatorConfig.authPort}');
      // ignore: avoid_print
      print('  Firestore ${EmulatorConfig.firestorePort}');
      // ignore: avoid_print
      print('  Functions ${EmulatorConfig.functionsPort}');
      // ignore: avoid_print
      print('  Storage ${EmulatorConfig.storagePort}');
    }
  } catch (error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Error setting up emulators: $error');
    }
  }
}
