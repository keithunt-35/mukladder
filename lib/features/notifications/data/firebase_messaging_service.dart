import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_notification_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FirebaseMessagingService implements PushNotificationService {
  FirebaseMessagingService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
