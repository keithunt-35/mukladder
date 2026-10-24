import 'package:cloud_firestore/cloud_firestore.dart';

import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge.dart';
import '../domain/match_result.dart';
import 'result_repository.dart';

class FirestoreResultRepository implements ResultRepository {
  FirestoreResultRepository({
    required this.challengeRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final ChallengeRepository challengeRepository;
  final FirebaseFirestore _firestore;

  @override
  Future<List<MatchResult>> getResults() async {
    final snapshot = await _firestore.collection('results').get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
  }

  @override
  Future<MatchResult> submitResult({
    required String challengeId,
    required String submittedBy,
    required String score,
    required DateTime submittedAt,
  }) async {
    final challenge = await challengeRepository.getChallenge(challengeId);
    if (challenge.status != ChallengeStatus.accepted) {
      throw StateError(
        'Results can only be submitted for accepted challenges.',
      );
    }
    if (challenge.challengerId != submittedBy &&
        challenge.challengedId != submittedBy) {
      throw StateError('Only a challenge participant can submit a result.');
    }
    final existing = await _firestore
        .collection('results')
        .where('challengeId', isEqualTo: challengeId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError(
        'A result has already been submitted for this challenge.',
      );
    }
    final reference = _firestore.collection('results').doc();
    await reference.set({
      'challengeId': challengeId,
      'submittedBy': submittedBy,
      'score': score,
      'status': ResultStatus.submitted.name,
      'submittedAt': Timestamp.fromDate(submittedAt),
    });
    final result = await _get(reference.id);
    return result;
  }

  @override
  Future<MatchResult> transitionResult({
    required String resultId,
    required String actorId,
    required ResultStatus status,
  }) async {
    final current = await _get(resultId);
    final updated = current.transitionTo(status);
    await _firestore.collection('results').doc(resultId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return updated;
  }

  Future<MatchResult> _get(String id) async {
    final document = await _firestore.collection('results').doc(id).get();
    final data = document.data();
    if (!document.exists || data == null) {
      throw StateError('Result was not found after it was written.');
    }
    return _fromData(document.id, data);
  }

  MatchResult _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => _fromData(document.id, document.data());

  MatchResult _fromData(String id, Map<String, dynamic> data) {
    final submittedAt = data['submittedAt'];
    return MatchResult(
      id: id,
      challengeId: data['challengeId'] as String,
      submittedBy: data['submittedBy'] as String,
      score: data['score'] as String,
      status: ResultStatus.values.byName(data['status'] as String),
      submittedAt: submittedAt is Timestamp
          ? submittedAt.toDate()
          : DateTime.parse(submittedAt as String),
    );
  }
}
