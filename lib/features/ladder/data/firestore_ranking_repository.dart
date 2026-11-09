import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../players/domain/player.dart';
import '../domain/ranking_entry.dart';
import 'ranking_repository.dart';

class FirestoreRankingRepository implements RankingRepository {
  FirestoreRankingRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    this.publicOnly = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final bool publicOnly;

  @override
  Future<List<RankingEntry>> getRanking() async {
    if (publicOnly) {
      return _getPublicRanking();
    }
    final snapshots = await Future.wait([
      _firestore.collection('rankings').orderBy('position').get(),
      _firestore.collection('players').get(),
    ]);
    return _fromDocuments(snapshots[0].docs, snapshots[1].docs);
  }

  @override
  Stream<List<RankingEntry>> watchRanking() {
    if (publicOnly) {
      return Stream.fromFuture(_getPublicRanking());
    }
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

  Future<List<RankingEntry>> _getPublicRanking() async {
    final response = await _functions.httpsCallable('getPublicLadder').call();
    final data = response.data;
    if (data is! List) {
      throw StateError('The public ladder response is invalid.');
    }
    return data
        .map((item) {
          if (item is! Map<Object?, Object?>) {
            throw StateError('A public ladder entry is invalid.');
          }
          final playerId = item['playerId'];
          final displayName = item['displayName'];
          final position = item['position'];
          final photoUrl = item['photoUrl'];
          final lastActivityAt = item['lastActivityAt'];
          final active = item['active'];
          if (playerId is! String ||
              displayName is! String ||
              position is! int ||
              position < 1 ||
              (photoUrl != null && photoUrl is! String) ||
              (lastActivityAt != null && lastActivityAt is! String) ||
              active is! bool) {
            throw StateError('A public ladder entry has invalid fields.');
          }
          final activityDate = lastActivityAt == null
              ? null
              : lastActivityAt is String
              ? DateTime.tryParse(lastActivityAt)
              : null;
          if (lastActivityAt != null && activityDate == null) {
            throw StateError('A public ladder activity date is invalid.');
          }
          return RankingEntry(
            position: position,
            player: Player(
              id: playerId,
              displayName: displayName,
              photoUrl: photoUrl is String ? photoUrl : null,
              lastActivityAt: activityDate,
              active: active,
            ),
          );
        })
        .toList(growable: false);
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
        lastActivityAt: _dateFrom(playerData['lastActivityAt']),
        paymentStatus: switch (playerData['paymentStatus']) {
          'pending' => PaymentStatus.pending,
          'paid' => PaymentStatus.paid,
          'overdue' => PaymentStatus.overdue,
          _ => PaymentStatus.unknown,
        },
        active:
            playerData['active'] as bool? ?? player['active'] as bool? ?? true,
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
