import '../domain/notification.dart';
import 'notification_repository.dart';

class InMemoryNotificationRepository implements NotificationRepository {
  InMemoryNotificationRepository({
    Iterable<AppNotification> notifications = const [],
  }) : _notifications = [...notifications];

  final List<AppNotification> _notifications;

  @override
  Future<NotificationSnapshot> getSnapshot() async {
    return NotificationSnapshot(
      notifications: List.unmodifiable(_notifications),
      state: NotificationSyncState.synchronized,
      lastSyncedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) {
      throw StateError('Notification was not found.');
    }
    _notifications[index] = AppNotification(
      id: _notifications[index].id,
      title: _notifications[index].title,
      body: _notifications[index].body,
      createdAt: _notifications[index].createdAt,
      readAt: DateTime.now(),
    );
  }
}
