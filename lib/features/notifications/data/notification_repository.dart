import '../domain/notification.dart';

abstract interface class NotificationRepository {
  Future<NotificationSnapshot> getSnapshot();

  Future<void> markRead(String notificationId);
}
