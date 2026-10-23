import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification.dart';
import 'notification_repository.dart';

class PersistentNotificationRepository implements NotificationRepository {
  PersistentNotificationRepository({
    required this.seedNotifications,
    required this.preferences,
  });

  static const _notificationsKey = 'notification_history';
  static const _syncedAtKey = 'notification_last_synced_at';

  final List<AppNotification> seedNotifications;
  final SharedPreferencesAsync preferences;

  @override
  Future<NotificationSnapshot> getSnapshot() async {
    try {
      final encoded = await preferences.getString(_notificationsKey);
      final syncedAtValue = await preferences.getString(_syncedAtKey);
      final stored = encoded == null
          ? seedNotifications
          : (jsonDecode(encoded) as List<dynamic>)
                .map(
                  (item) => AppNotification.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      final lastSyncedAt = syncedAtValue == null
          ? null
          : DateTime.tryParse(syncedAtValue);
      final stale =
          lastSyncedAt == null ||
          DateTime.now().difference(lastSyncedAt).inHours >= 24;
      return NotificationSnapshot(
        notifications: List.unmodifiable(stored),
        state: stale
            ? NotificationSyncState.stale
            : NotificationSyncState.synchronized,
        lastSyncedAt: lastSyncedAt,
      );
    } catch (error) {
      return NotificationSnapshot(
        notifications: List.unmodifiable(seedNotifications),
        state: NotificationSyncState.rejected,
        rejectedWrite: 'Notification history could not be read: $error',
      );
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    final snapshot = await getSnapshot();
    final index = snapshot.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) {
      throw StateError('Notification was not found.');
    }
    final updated = [...snapshot.notifications];
    final notification = updated[index];
    updated[index] = AppNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      createdAt: notification.createdAt,
      readAt: DateTime.now(),
    );
    try {
      await preferences.setString(
        _notificationsKey,
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      throw StateError('Notification read state was rejected: $error');
    }
  }
}
