import 'package:cloud_firestore/cloud_firestore.dart';

class RosterAccountLinker {
  RosterAccountLinker({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Links a seeded tournament roster player (e.g. 'player-1') to an
  /// authenticated Firebase Auth user UID.
  Future<void> linkSeededPlayer({
    required String uid,
    required String rosterPlayerId,
  }) async {
    if (uid.isEmpty || rosterPlayerId.isEmpty) {
      throw ArgumentError('Both Auth UID and roster player ID are required.');
    }

    final playerReference = _firestore.collection('players').doc(rosterPlayerId);
    final snapshot = await playerReference.get();
    if (!snapshot.exists) {
      throw StateError('Seeded roster player $rosterPlayerId was not found.');
    }

    await playerReference.update({
      'userId': uid,
      'linkedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
