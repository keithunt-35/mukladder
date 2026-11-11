import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'emulator_config.dart';
import 'features/notifications/data/firebase_messaging_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseMessagingService().initialize();
      await setupEmulators();
    } on FirebaseException catch (error) {
      // Log the error but continue to allow the app to run in offline/demo mode
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          context: ErrorDescription('Firebase initialization'),
        ),
      );
    }
  }
  runApp(const ProviderScope(child: MukladderApp()));
}
