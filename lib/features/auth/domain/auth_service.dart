import 'app_user.dart';

abstract interface class AuthService {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();
}
