import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    UserProfileRepository? profileRepository,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _profileRepository = profileRepository ?? UserProfileRepository();

  final FirebaseAuth _firebaseAuth;
  final UserProfileRepository _profileRepository;

  @override
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().asyncMap(_loadAppUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final appUser = await _loadAppUser(credential.user);
    if (appUser == null) {
      throw StateError('Firebase returned no signed-in user.');
    }
    return appUser;
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    final appUser = _toAppUser(_firebaseAuth.currentUser)!;
    await _profileRepository.createPlayerProfile(user: appUser, email: email);
    return appUser;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  AppUser? _toAppUser(User? user) {
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      displayName: user.displayName ?? user.email ?? 'MUKLadder player',
      role: AppRole.player,
    );
  }

  Future<AppUser?> _loadAppUser(User? user) async {
    final basicUser = _toAppUser(user);
    if (basicUser == null) {
      return null;
    }
    try {
      return await _profileRepository.getCurrentUser(basicUser.id);
    } on StateError {
      return basicUser;
    }
  }
}
