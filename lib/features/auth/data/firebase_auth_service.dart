import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  AppUser get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No Firebase user is signed in.');
    }

    return AppUser(
      id: user.uid,
      displayName: user.displayName ?? user.email ?? 'MUKLadder player',
      role: AppRole.player,
    );
  }
}
