import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
