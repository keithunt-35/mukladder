import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/player.dart';
import 'player_repository.dart';

class FirestorePlayerRepository implements PlayerRepository {
  FirestorePlayerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Player>> getPlayers() async {
    final snapshot = await _firestore.collection('players').get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
  }

  Player _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    return Player(
      id: document.id,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      lastActivityAt: _dateFrom(data['lastActivityAt']),
      paymentStatus: switch (data['paymentStatus']) {
        'pending' => PaymentStatus.pending,
        'paid' => PaymentStatus.paid,
        'overdue' => PaymentStatus.overdue,
        _ => PaymentStatus.unknown,
      },
      active: data['active'] as bool? ?? true,
    );
  }

  DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
