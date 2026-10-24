import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  try {
    return ref.watch(authServiceProvider).currentUser;
  } on StateError {
    return null;
  }
});
