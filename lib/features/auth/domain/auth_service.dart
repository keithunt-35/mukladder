import 'dart:typed_data';

import 'app_user.dart';

abstract interface class AuthService {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    Uint8List? profilePhoto,
  });

  Future<AppUser> updateProfilePhoto({required Uint8List profilePhoto});

  Future<void> signOut();
}
