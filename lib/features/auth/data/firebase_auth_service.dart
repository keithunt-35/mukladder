import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_service.dart';
import '../../players/data/firebase_profile_photo_repository.dart';
import 'user_profile_repository.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    UserProfileRepository? profileRepository,
    FirebaseProfilePhotoRepository? profilePhotoRepository,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _profileRepository = profileRepository ?? UserProfileRepository(),
       _profilePhotoRepository =
           profilePhotoRepository ?? FirebaseProfilePhotoRepository();

  final FirebaseAuth _firebaseAuth;
  final UserProfileRepository _profileRepository;
  final FirebaseProfilePhotoRepository _profilePhotoRepository;

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
    Uint8List? profilePhoto,
  }) async {
    if (profilePhoto != null &&
        (profilePhoto.isEmpty ||
            profilePhoto.length >
                FirebaseProfilePhotoRepository.maximumPhotoSizeBytes)) {
      throw ArgumentError.value(
        profilePhoto.length,
        'profilePhoto.length',
        'Choose an image that is no larger than 5 MB.',
      );
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final currentUser = credential.user!;
    await currentUser.updateDisplayName(displayName.trim());
    final appUser = AppUser(
      id: currentUser.uid,
      displayName: currentUser.displayName ?? displayName.trim(),
      role: AppRole.player,
    );
    await _profileRepository.createPlayerProfile(user: appUser, email: email);

    if (profilePhoto == null) {
      return appUser;
    }

    try {
      final photoUrl = await _profilePhotoRepository.uploadPhoto(
        userId: currentUser.uid,
        bytes: profilePhoto,
      );
      await _profilePhotoRepository.savePhotoUrl(
        userId: currentUser.uid,
        displayName: appUser.displayName,
        photoUrl: photoUrl,
      );
      return AppUser(
        id: appUser.id,
        displayName: appUser.displayName,
        role: appUser.role,
        photoUrl: photoUrl,
      );
    } on FirebaseException catch (error) {
      try {
        await _firebaseAuth.signOut();
      } on FirebaseAuthException catch (signOutError) {
        throw StateError(
          'Your account was created, but the profile photo could not be '
          'saved and sign-out failed. Sign in and retry from your profile. '
          '${signOutError.message ?? signOutError.code}',
        );
      }
      throw StateError(
        'Your account was created, but ${_profilePhotoFailure(error)} '
        'Sign in and retry from your profile.',
      );
    }
  }

  String _profilePhotoFailure(FirebaseException error) {
    if (error.plugin == 'firebase_storage') {
      return switch (error.code) {
        'object-not-found' =>
          'Firebase Storage cannot find the uploaded photo. Verify that the '
              'project bucket exists and matches the app configuration.',
        'bucket-not-found' =>
          'the configured Firebase Storage bucket is not available.',
        'unauthorized' || 'unauthenticated' =>
          'Firebase Storage rejected the upload. Verify the deployed Storage '
              'rules allow your own photo.',
        _ =>
          'the profile photo could not be uploaded '
              '(${error.code}: ${error.message ?? 'unknown error'}).',
      };
    }
    return 'the profile photo could not be saved '
        '(${error.plugin}/${error.code}: ${error.message ?? 'unknown error'}).';
  }

  @override
  Future<AppUser> updateProfilePhoto({required Uint8List profilePhoto}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Sign in before updating your profile photo.');
    }

    final photoUrl = await _profilePhotoRepository.uploadPhoto(
      userId: user.uid,
      bytes: profilePhoto,
    );
    await _profilePhotoRepository.savePhotoUrl(
      userId: user.uid,
      displayName: user.displayName ?? user.email ?? 'MUKLadder player',
      photoUrl: photoUrl,
    );
    return _profileRepository.getCurrentUser(user.uid);
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
      photoUrl: user.photoURL,
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
