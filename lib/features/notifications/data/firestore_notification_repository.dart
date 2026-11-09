import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/notification.dart';
import 'notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({
    required this.recipientId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String recipientId;
  final FirebaseFirestore _firestore;

  @override
  Future<NotificationSnapshot> getSnapshot() async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .get();
    return NotificationSnapshot(
      notifications: snapshot.docs.map(_fromDocument).toList(growable: false),
      state: NotificationSyncState.synchronized,
      lastSyncedAt: DateTime.now(),
    );
  }

  /// Real-time stream of the notification snapshot for this recipient.
  Stream<NotificationSnapshot> watchSnapshot() {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => NotificationSnapshot(
            notifications: snapshot.docs
                .map(_fromDocument)
                .toList(growable: false),
            state: NotificationSyncState.synchronized,
            lastSyncedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  AppNotification _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    final readAt = data['readAt'];
    return AppNotification(
      id: document.id,
      title: data['title'] as String,
      body: data['body'] as String,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.parse(createdAt as String),
      readAt: readAt is Timestamp
          ? readAt.toDate()
          : readAt is String
          ? DateTime.tryParse(readAt)
          : null,
    );
  }
}
