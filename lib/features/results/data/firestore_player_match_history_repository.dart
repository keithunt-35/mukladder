import 'package:cloud_firestore/cloud_firestore.dart';

import '../../challenges/domain/challenge.dart';
import '../domain/match_result.dart';
import '../domain/player_match_history_entry.dart';

class FirestorePlayerMatchHistoryRepository {
  FirestorePlayerMatchHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<PlayerMatchHistoryEntry>> getHistory(String userId) async {
    final challengeSnapshots = await Future.wait([
      _firestore
          .collection('challenges')
          .where('challengerId', isEqualTo: userId)
          .get(),
      _firestore
          .collection('challenges')
          .where('challengedId', isEqualTo: userId)
          .get(),
    ]);
    final challenges = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in challengeSnapshots) {
      for (final document in snapshot.docs) {
        challenges[document.id] = document;
      }
    }

    final playerSnapshot = await _firestore.collection('players').get();
    final playerNamesById = <String, String>{};
    for (final player in playerSnapshot.docs) {
      final name = player.data()['displayName'] as String?;
      if (name == null || name.isEmpty) {
        continue;
      }
      playerNamesById[player.id] = name;
      final linkedUserId = player.data()['userId'] as String?;
      if (linkedUserId != null) {
        playerNamesById[linkedUserId] = name;
      }
    }

    final entries = await Future.wait(
      challenges.values.map((document) async {
        final challenge = document.data();
        final challengerId = challenge['challengerId'] as String;
        final challengedId = challenge['challengedId'] as String;
        final opponentId = challengerId == userId ? challengedId : challengerId;
        final resultSnapshot = await _firestore
            .collection('results')
            .where('challengeId', isEqualTo: document.id)
            .limit(1)
            .get();
        if (resultSnapshot.docs.isEmpty) {
          return null;
        }

        final result = resultSnapshot.docs.first.data();
        return PlayerMatchHistoryEntry(
          challengeId: document.id,
          opponentName: playerNamesById[opponentId] ?? 'Opponent',
          score: result['score'] as String,
          status: ResultStatus.values.byName(result['status'] as String),
          challengeType: ChallengeType.values.byName(
            challenge['type'] as String,
          ),
          playedAt:
              _dateFrom(challenge['proposedDate']) ??
              _dateFrom(result['submittedAt']) ??
              _dateFrom(challenge['createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0),
        );
      }),
    );

    return entries.whereType<PlayerMatchHistoryEntry>().toList()
      ..sort((first, second) => second.playedAt.compareTo(first.playedAt));
  }

  DateTime? _dateFrom(Object? value) => value is Timestamp
      ? value.toDate()
      : value is String
      ? DateTime.tryParse(value)
      : null;
}
