import '../domain/app_user.dart';
import '../domain/auth_service.dart';

class DemoAuthService implements AuthService {
  @override
  AppUser get currentUser => const AppUser(
    id: 'demo-player-1',
    displayName: 'Tugume Keith',
    role: AppRole.player,
  );
}
