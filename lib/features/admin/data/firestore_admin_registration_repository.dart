import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../notifications/domain/notification.dart';
import '../domain/pending_registration.dart';

class FirestoreAdminRegistrationRepository {
  FirestoreAdminRegistrationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<PendingRegistration>> watchPendingRegistrations() {
    return _firestore
        .collection('users')
        .where('registrationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final registrations = snapshot.docs
              .map(_fromDocument)
              .toList(growable: false);
          registrations.sort((first, second) {
            return (first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                );
          });
          return registrations;
        });
  }

  Stream<List<AppNotification>> watchAdminNotifications(String adminId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((document) {
            final data = document.data();
            final createdAt = data['createdAt'];
            if (createdAt is! Timestamp) {
              throw StateError(
                'Admin notification ${document.id} has no server timestamp.',
              );
            }
            return AppNotification(
              id: document.id,
              title: data['title'] as String,
              body: data['body'] as String,
              createdAt: createdAt.toDate(),
            );
          }).toList();
          notifications.sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
          return notifications.take(20).toList(growable: false);
        });
  }

  Future<int> suggestedPosition() async {
    final snapshot = await _firestore.collection('rankings').get();
    return snapshot.size + 1;
  }

  Future<void> approveRegistration({
    required String userId,
    required int initialPosition,
    required bool paymentVerified,
  }) async {
    await _functions.httpsCallable('approvePlayerRegistration').call({
      'userId': userId,
      'initialPosition': initialPosition,
      'paymentVerified': paymentVerified,
    });
  }

  PendingRegistration _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    return PendingRegistration(
      userId: document.id,
      displayName: data['displayName'] as String? ?? 'Unnamed player',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      joinRequestStatus: data['joinRequestStatus'] as String? ?? 'requested',
      paymentReference: data['paymentReference'] as String?,
    );
  }
}
