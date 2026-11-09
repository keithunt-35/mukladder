import 'dart:async';

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
    final snapshots = await Future.wait([
      _firestore.collection('rankings').orderBy('position').get(),
      _firestore.collection('players').get(),
    ]);
    return _fromDocuments(snapshots[0].docs, snapshots[1].docs);
  }

  @override
  Stream<List<RankingEntry>> watchRanking() {
    final controller = StreamController<List<RankingEntry>>();
    QuerySnapshot<Map<String, dynamic>>? rankingSnapshot;
    QuerySnapshot<Map<String, dynamic>>? playerSnapshot;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    rankingSubscription;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    playerSubscription;

    void emitIfReady() {
      if (rankingSnapshot == null || playerSnapshot == null) {
        return;
      }
      controller.add(
        _fromDocuments(rankingSnapshot!.docs, playerSnapshot!.docs),
      );
    }

    controller
      ..onListen = () {
        rankingSubscription = _firestore
            .collection('rankings')
            .orderBy('position')
            .snapshots()
            .listen((snapshot) {
              rankingSnapshot = snapshot;
              emitIfReady();
            }, onError: controller.addError);
        playerSubscription = _firestore
            .collection('players')
            .snapshots()
            .listen((snapshot) {
              playerSnapshot = snapshot;
              emitIfReady();
            }, onError: controller.addError);
      }
      ..onCancel = () async {
        await rankingSubscription.cancel();
        await playerSubscription.cancel();
      };

    return controller.stream;
  }

  List<RankingEntry> _fromDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rankingDocuments,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> playerDocuments,
  ) {
    final playersById = {
      for (final document in playerDocuments) document.id: document.data(),
    };
    return rankingDocuments
        .map((document) => _fromDocument(document, playersById))
        .toList(growable: false);
  }

  RankingEntry _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, Map<String, dynamic>> playersById,
  ) {
    final data = document.data();
    final player = data['player'] as Map<String, dynamic>? ?? const {};
    final playerId = player['id'] as String? ?? data['playerId'] as String;
    final playerData = playersById[playerId] ?? const <String, dynamic>{};
    return RankingEntry(
      position: (data['position'] as num).toInt(),
      player: Player(
        id: playerId,
        displayName:
            playerData['displayName'] as String? ??
            player['displayName'] as String,
        photoUrl:
            playerData['photoUrl'] as String? ?? player['photoUrl'] as String?,
        lastActivityAt:
            _dateFrom(playerData['lastActivityAt']) ??
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
