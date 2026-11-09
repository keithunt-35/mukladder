import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';
import '../../challenges/application/challenge_providers.dart';
import '../../challenges/domain/challenge.dart';
import '../data/firestore_notification_repository.dart';
import '../data/persistent_notification_repository.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';

/// Generates synthetic in-app notification entries from pending incoming
/// challenges so the Alerts tab reflects new challenges even before the
/// backend writes a push notification record.
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
    // Use persistent storage with synthetic seeds for unauthenticated state.
    final seeds = ref.watch(notificationSeedProvider);
    return PersistentNotificationRepository(
      seedNotifications: seeds,
      preferences: SharedPreferencesAsync(),
    );
  }
  return FirestoreNotificationRepository(recipientId: user.id);
});

/// Stream of notifications for the current user.
/// Authenticated users get Firestore real-time updates; unauthenticated users
/// get a one-shot snapshot from the persistent local store.
final notificationsProvider = StreamProvider<NotificationSnapshot>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    final repository = ref.watch(notificationRepositoryProvider);
    return Stream.fromFuture(repository.getSnapshot());
  }
  // Use the repository from the provider so tests can override it.
  final repository = ref.watch(notificationRepositoryProvider);
  if (repository is FirestoreNotificationRepository) {
    return repository.watchSnapshot();
  }
  // Fallback for non-Firestore repositories (tests / demo).
  return Stream.fromFuture(repository.getSnapshot());
});
