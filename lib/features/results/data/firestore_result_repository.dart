import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge.dart';
import '../../challenges/domain/challenge_rules.dart';
import '../domain/match_result.dart';
import '../domain/match_score.dart';
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
    final challenges = await challengeRepository.getChallenges();
    final snapshots = await Future.wait(
      challenges.map(
        (challenge) => _firestore
            .collection('results')
            .where('challengeId', isEqualTo: challenge.id)
            .get(),
      ),
    );
    final documents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        documents[document.id] = document;
      }
    }
    return documents.values.map(_fromDocument).toList(growable: false);
  }

  /// Real-time stream of results.  Listens to the challenges stream and re-fans
  /// out individual result snapshots whenever the challenge list changes.
  @override
  Stream<List<MatchResult>> watchResults() {
    final controller = StreamController<List<MatchResult>>();
    StreamSubscription<List<dynamic>>? challengeSub;
    final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
    resultSubs = {};
    final Map<String, List<MatchResult>> resultsByChallenge = {};

    void emitAll() {
      final all = <MatchResult>[];
      for (final results in resultsByChallenge.values) {
        all.addAll(results);
      }
      controller.add(List.unmodifiable(all));
    }

    controller.onListen = () {
      challengeSub = challengeRepository.watchChallenges().listen(
        (challenges) {
          final currentIds = challenges.map((c) => c.id).toSet();
          // Cancel subscriptions for challenges no longer relevant.
          final stale = resultSubs.keys
              .where((id) => !currentIds.contains(id))
              .toList();
          for (final id in stale) {
            resultSubs.remove(id)?.cancel();
            resultsByChallenge.remove(id);
          }
          // Add subscriptions for new challenges.
          for (final challenge in challenges) {
            if (resultSubs.containsKey(challenge.id)) continue;
            resultSubs[challenge.id] = _firestore
                .collection('results')
                .where('challengeId', isEqualTo: challenge.id)
                .snapshots()
                .listen((snap) {
                  resultsByChallenge[challenge.id] = snap.docs
                      .map(_fromDocument)
                      .toList(growable: false);
                  emitAll();
                }, onError: controller.addError);
          }
        },
        onError: controller.addError,
      );
    };
    controller.onCancel = () async {
      await challengeSub?.cancel();
      for (final sub in resultSubs.values) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<MatchResult> submitResult({
    required String challengeId,
    required String submittedBy,
    required String score,
    required DateTime submittedAt,
  }) async {
    final signedInUserId = FirebaseAuth.instance.currentUser?.uid;
    if (signedInUserId == null || signedInUserId != submittedBy) {
      throw StateError('The signed-in user must submit this result.');
    }
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
    if (!MatchScore.isValid(score)) {
      throw const FormatException(
        'Use scores such as 6-4, 6-3 with one or more sets.',
      );
    }
    if (challenge.proposedDate != null) {
      ChallengeRules.validateResultSubmission(
        matchDate: challenge.proposedDate!,
        submittedAt: submittedAt,
      );
    }
    final challengeReference = _firestore
        .collection('challenges')
        .doc(challengeId);
    final reference = _firestore.collection('results').doc();
    await _firestore.runTransaction((transaction) async {
      final currentChallenge = await transaction.get(challengeReference);
      final data = currentChallenge.data();
      if (data == null || data['status'] != ChallengeStatus.accepted.name) {
        throw StateError(
          'Results can only be submitted for accepted challenges.',
        );
      }
      if (data['resultId'] != null) {
        throw StateError(
          'A result has already been submitted for this challenge.',
        );
      }
      transaction
        ..set(reference, {
          'challengeId': challengeId,
          'submittedBy': submittedBy,
          'score': score.trim(),
          'status': ResultStatus.submitted.name,
          'submittedAt': FieldValue.serverTimestamp(),
        })
        ..update(challengeReference, {
          'resultId': reference.id,
          'resultSubmittedAt': FieldValue.serverTimestamp(),
        });
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
    final signedInUserId = FirebaseAuth.instance.currentUser?.uid;
    if (signedInUserId == null || signedInUserId != actorId) {
      throw StateError('The signed-in user must review this result.');
    }
    final resultReference = _firestore.collection('results').doc(resultId);
    MatchResult? updated;
    await _firestore.runTransaction((transaction) async {
      final resultSnapshot = await transaction.get(resultReference);
      final resultData = resultSnapshot.data();
      if (resultData == null) {
        throw StateError('Result was not found.');
      }
      final current = _fromData(resultId, resultData);
      final challengeReference = _firestore
          .collection('challenges')
          .doc(current.challengeId);
      final challengeSnapshot = await transaction.get(challengeReference);
      final challengeData = challengeSnapshot.data();
      if (challengeData == null) {
        throw StateError('Challenge was not found.');
      }
      if (actorId != challengeData['challengerId'] &&
          actorId != challengeData['challengedId']) {
        throw StateError('Only challenge participants can review a result.');
      }
      if (actorId == current.submittedBy) {
        throw StateError(
          'The result submitter cannot confirm their own score.',
        );
      }
      final next = current.transitionTo(status);
      transaction.update(resultReference, {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': actorId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      if (status == ResultStatus.confirmed) {
        transaction.update(challengeReference, {
          'status': ChallengeStatus.completed.name,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      updated = next;
    });
    return updated!;
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
