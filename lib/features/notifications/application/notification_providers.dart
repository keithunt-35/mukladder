import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';
import '../../challenges/application/challenge_providers.dart';
import '../../challenges/domain/challenge.dart';
import '../data/firestore_notification_repository.dart';
import '../data/persistent_notification_repository.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';

final notificationSeedProvider = Provider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }
  final challenges = ref
      .watch(challengesProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <Challenge>[]);
  return [
    for (final challenge in challenges)
      if (challenge.challengedId == user.id &&
          challenge.status == ChallengeStatus.pending)
        AppNotification(
          id: 'challenge-${challenge.id}',
          title: 'Incoming challenge',
          body: 'You have a pending challenge to review.',
          createdAt: challenge.createdAt,
        ),
  ];
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return PersistentNotificationRepository(
      seedNotifications: const [],
      preferences: SharedPreferencesAsync(),
    );
  }
  if (defaultTargetPlatform != TargetPlatform.android) {
    return PersistentNotificationRepository(
      seedNotifications: ref.watch(notificationSeedProvider),
      preferences: SharedPreferencesAsync(),
    );
  }
  return FirestoreNotificationRepository(recipientId: user.id);
});

final notificationsProvider = FutureProvider<NotificationSnapshot>((ref) {
  return ref.watch(notificationRepositoryProvider).getSnapshot();
});
