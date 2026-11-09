import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../notifications/domain/notification.dart';
import 'admin_registration_providers.dart';

final adminNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <AppNotification>[]);
  }
  return ref
      .watch(adminRegistrationRepositoryProvider)
      .watchAdminNotifications(user.id);
});
