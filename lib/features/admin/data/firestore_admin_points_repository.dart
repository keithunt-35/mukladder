import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/admin_player_points.dart';

class FirestoreAdminPointsRepository {
  FirestoreAdminPointsRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<AdminPlayerPoints>> watchPlayerPoints() {
    final controller = StreamController<List<AdminPlayerPoints>>();
    QuerySnapshot<Map<String, dynamic>>? playersSnapshot;
    QuerySnapshot<Map<String, dynamic>>? pointsSnapshot;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    playersSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? pointsSubscription;

    void emitIfReady() {
      if (playersSnapshot == null || pointsSnapshot == null) {
        return;
      }

      final totalsByPlayerId = {
        for (final document in pointsSnapshot!.docs)
          document.id: document.data(),
      };
      final players =
          playersSnapshot!.docs.map((document) {
            final data = document.data();
            final points = totalsByPlayerId[document.id]?['totalPoints'];
            return AdminPlayerPoints(
              playerId: document.id,
              displayName: data['displayName'] as String? ?? 'Unnamed player',
              totalPoints: points is num ? points.toInt() : 0,
              active: data['active'] as bool? ?? true,
              registrationStatus: data['registrationStatus'] as String?,
            );
          }).toList()..sort(
            (first, second) => first.displayName.toLowerCase().compareTo(
              second.displayName.toLowerCase(),
            ),
          );
      controller.add(List.unmodifiable(players));
    }

    controller
      ..onListen = () {
        playersSubscription = _firestore
            .collection('players')
            .snapshots()
            .listen((snapshot) {
              playersSnapshot = snapshot;
              emitIfReady();
            }, onError: controller.addError);
        pointsSubscription = _firestore
            .collection('playerPoints')
            .snapshots()
            .listen((snapshot) {
              pointsSnapshot = snapshot;
              emitIfReady();
            }, onError: controller.addError);
      }
      ..onCancel = () async {
        await playersSubscription?.cancel();
        await pointsSubscription?.cancel();
      };

    return controller.stream;
  }

  Future<void> addPoints({
    required String playerId,
    required int points,
    required String reason,
  }) async {
    final requestId = _firestore.collection('playerPointEvents').doc().id;
    await _functions.httpsCallable('addPlayerPoints').call({
      'requestId': requestId,
      'playerId': playerId,
      'points': points,
      'reason': reason,
    });
  }
}
