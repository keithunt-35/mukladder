import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../players/domain/player.dart';

/// View model used by the Treasurer screen.
class TreasurerPlayerEntry {
  const TreasurerPlayerEntry({
    required this.playerId,
    required this.displayName,
    required this.position,
    required this.paymentStatus,
    required this.active,
    this.paymentReference,
  });

  final String playerId;
  final String displayName;
  final int position;
  final PaymentStatus paymentStatus;
  final bool active;
  final String? paymentReference;
}

/// Data access for Treasurer-specific operations.
/// Payment-status reads come from the players collection via a real-time
/// stream; mutations go through a trusted Cloud Function so that only an
/// authenticated Treasurer may change this field and an audit event is
/// recorded server-side.
class FirestoreTreasurerRepository {
  FirestoreTreasurerRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Updates a player's payment status via the trusted [updatePaymentStatus]
  /// Cloud Function.  The function enforces Treasurer role authorization and
  /// writes an audit event.
  Future<void> updatePaymentStatus({
    required String playerId,
    required PaymentStatus status,
    String? note,
  }) async {
    await _functions.httpsCallable('updatePaymentStatus').call({
      'playerId': playerId,
      'status': status.name,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Real-time stream of every player's payment status, ordered
  /// alphabetically by display name.
  Stream<List<TreasurerPlayerEntry>> watchPaymentOverview() {
    return _firestore
        .collection('players')
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return TreasurerPlayerEntry(
                  playerId: doc.id,
                  displayName:
                      data['displayName'] as String? ?? 'Unnamed player',
                  position: data['position'] as int? ?? 0,
                  paymentStatus: _parseStatus(
                    data['paymentStatus'] as String?,
                  ),
                  paymentReference: data['paymentReference'] as String?,
                  active: data['active'] as bool? ?? true,
                );
              })
              .toList(growable: false),
        );
  }

  PaymentStatus _parseStatus(String? value) => switch (value) {
    'pending' => PaymentStatus.pending,
    'paid' => PaymentStatus.paid,
    'overdue' => PaymentStatus.overdue,
    _ => PaymentStatus.unknown,
  };
}
