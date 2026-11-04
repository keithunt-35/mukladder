import 'package:cloud_firestore/cloud_firestore.dart';

import '../../players/domain/player.dart';
import '../domain/ranking_entry.dart';
import 'ranking_repository.dart';

class FirestoreRankingRepository implements RankingRepository {
  FirestoreRankingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<RankingEntry>> getRanking() async {
    final snapshot = await _firestore
        .collection('rankings')
        .orderBy('position')
        .get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
  }

  @override
  Stream<List<RankingEntry>> watchRanking() {
    return _firestore
        .collection('rankings')
        .orderBy('position')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_fromDocument).toList(growable: false),
        );
  }

  RankingEntry _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final player = data['player'] as Map<String, dynamic>? ?? const {};
    return RankingEntry(
      position: (data['position'] as num).toInt(),
      player: Player(
        id: player['id'] as String? ?? data['playerId'] as String,
        displayName: player['displayName'] as String,
        lastActivityAt:
            _dateFrom(player['lastActivityAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        paymentStatus: PaymentStatus.unknown,
        active: player['active'] as bool? ?? true,
      ),
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
