import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/admin_overview.dart';

class FirestoreAdminOverviewRepository {
  FirestoreAdminOverviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<AdminOverview> getOverview() async {
    final snapshots = await Future.wait([
      _firestore.collection('players').get(),
      _firestore.collection('challenges').get(),
      _firestore.collection('results').get(),
      _firestore.collection('auditEvents').get(),
    ]);

    final players = snapshots[0].docs;
    final challenges = snapshots[1].docs;
    final results = snapshots[2].docs;

    return AdminOverview(
      totalPlayers: players.length,
      activePlayers: players.where((player) {
        return player.data()['active'] != false;
      }).length,
      pendingChallenges: challenges.where((challenge) {
        return challenge.data()['status'] == 'pending';
      }).length,
      unresolvedResults: results.where((result) {
        final status = result.data()['status'];
        return status == 'submitted' || status == 'disputed';
      }).length,
      auditEvents: snapshots[3].size,
    );
  }
}
