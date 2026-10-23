abstract interface class PushNotificationService {
  Future<void> initialize();
}

/// Explicit no-op boundary until Firebase Cloud Messaging is configured.
class UnconfiguredPushNotificationService implements PushNotificationService {
  @override
  Future<void> initialize() async {
    throw StateError(
      'Push notifications are unavailable until Firebase Cloud Messaging '
      'is configured.',
    );
  }
}
