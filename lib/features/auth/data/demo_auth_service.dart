import '../domain/app_user.dart';
import '../domain/auth_service.dart';

class DemoAuthService implements AuthService {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(
    const AppUser(
      id: 'demo-player-1',
      displayName: 'Tugume Keith',
      role: AppRole.player,
    ),
  );

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => const AppUser(
    id: 'demo-player-1',
    displayName: 'Tugume Keith',
    role: AppRole.player,
  );

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async => AppUser(
    id: 'demo-player-1',
    displayName: displayName,
    role: AppRole.player,
  );

  @override
  Future<void> signOut() async {}
}
