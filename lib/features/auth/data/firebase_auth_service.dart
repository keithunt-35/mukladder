import 'dart:async';
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

  String _profileCreationFailure(FirebaseException error) {
    if (error.plugin == 'cloud_firestore' &&
        error.code == 'permission-denied') {
      return 'Firebase Authentication created your account, but Firestore '
          'blocked saving its player profile. Publish the current firestore.rules '
          'to project mukladder-4351c, then sign in again to finish setup '
          '(cloud_firestore/permission-denied).';
    }
    return 'Firebase Authentication created your account, but the Firestore '
        'player profile could not be saved '
        '(${error.plugin}/${error.code}: '
        '${error.message ?? 'no additional details'}). Sign in again after '
        'fixing the Firebase setup.';
  }

  @override
  Stream<AppUser?> get authStateChanges {
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<AppUser>? profileSubscription;
    var generation = 0;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSubscription = _firebaseAuth.authStateChanges().listen(
          (user) {
            final currentGeneration = ++generation;
            final previousProfileSubscription = profileSubscription;
            profileSubscription = null;
            if (previousProfileSubscription != null) {
              unawaited(previousProfileSubscription.cancel());
            }
            if (user == null) {
              controller.add(null);
              return;
            }

            profileSubscription = _profileRepository
                .watchCurrentUser(user.uid)
                .listen(
                  (appUser) {
                    if (currentGeneration == generation) {
                      controller.add(appUser);
                    }
                  },
                  onError: (Object error, StackTrace stackTrace) {
                    if (currentGeneration == generation) {
                      controller.addError(error, stackTrace);
                    }
                  },
                );
          },
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(error, stackTrace);
          },
        );
      },
      onCancel: () async {
        generation++;
        await authSubscription?.cancel();
        await profileSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase returned no signed-in user.');
    }
    return _profileRepository.getOrCreateSignedInPlayer(
      uid: user.uid,
      email: user.email ?? email.trim(),
      displayName: user.displayName ?? '',
    );
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    AppRole role = AppRole.player,
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
      role: role,
      registrationApproved: role == AppRole.player ? false : true,
      registrationStatus: role == AppRole.player ? 'notRequested' : 'approved',
      joinRequestStatus: 'notRequested',
    );
    try {
      await _profileRepository.createPlayerProfile(
        user: appUser,
        email: email.trim(),
      );
    } on FirebaseException catch (error) {
      try {
        await _firebaseAuth.signOut();
      } on FirebaseAuthException catch (signOutError) {
        throw StateError(
          'Your Authentication account was created, but its player profile '
          'could not be saved and sign-out failed. '
          '${_profileCreationFailure(error)} '
          '${signOutError.message ?? signOutError.code}',
        );
      }
      throw StateError(_profileCreationFailure(error));
    }

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
        registrationApproved: appUser.registrationApproved,
        registrationStatus: appUser.registrationStatus,
        joinRequestStatus: appUser.joinRequestStatus,
      );
    } on FirebaseException catch (error) {
      // Account + profile created successfully; photo upload failed.
      // Do NOT sign out — the account is valid.  Report so the user
      // can retry from the Profile screen.
      throw StateError(
        'Your account was created, but ${_profilePhotoFailure(error)} '
        'Sign in and retry uploading your photo from the Profile screen.',
      );
    }
  }

  String _profilePhotoFailure(FirebaseException error) {
    if (error.plugin == 'firebase_storage') {
      return switch (error.code) {
        'object-not-found' =>
          'Firebase Storage cannot find this photo in the configured bucket. '
              'Ask the project owner to confirm or create the bucket configured '
              'for this app, then check Storage > Files for the uploaded photo.',
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
  Future<void> recordActivity() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _profileRepository.recordActivity(user.uid);
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
