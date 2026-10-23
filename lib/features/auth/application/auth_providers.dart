import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_auth_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return DemoAuthService();
});

final currentUserProvider = Provider<AppUser>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});
