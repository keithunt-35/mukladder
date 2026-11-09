import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/challenge.dart';
import '../domain/challenge_rules.dart';
import 'challenge_repository.dart';

class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Challenge>> getChallenges() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw StateError('A signed-in user is required to load challenges.');
    }
    final snapshots = await Future.wait([
      _firestore
          .collection('challenges')
          .where('challengerId', isEqualTo: userId)
          .get(),
      _firestore
          .collection('challenges')
          .where('challengedId', isEqualTo: userId)
          .get(),
    ]);
    final documents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        documents[document.id] = document;
      }
    }
    return documents.values.map(_fromDocument).toList(growable: false);
  }

  @override
  Future<Challenge> getChallenge(String challengeId) async {
    final document = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .get();
    final data = document.data();
    if (!document.exists || data == null) {
      throw StateError('Challenge was not found.');
    }
    return _fromData(document.id, data);
  }

  @override
  Future<Challenge> createNormalChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
    int? challengerPosition,
    int? challengedPosition,
    DateTime? proposedDate,
    DateTime? cooldownStartedAt,
  }) {
    if (challengerPosition == null || challengedPosition == null) {
      throw ArgumentError('Both players must have a current ladder position.');
    }
    ChallengeRules.validateNormalPlacement(
      challengerPosition: challengerPosition,
      challengedPosition: challengedPosition,
      requestedAt: createdAt,
      proposedDate: proposedDate,
    );
    if (cooldownStartedAt != null) {
      ChallengeRules.validateTwoDayCooldown(
        cooldownStartedAt: cooldownStartedAt,
        requestedAt: createdAt,
      );
    }
    return _create(
      challengerId: challengerId,
      challengedId: challengedId,
      type: ChallengeType.normal,
      createdAt: createdAt,
      proposedDate: proposedDate,
      extra: {
        'challengerPosition': challengerPosition,
        'challengedPosition': challengedPosition,
        'cooldownStartedAt': cooldownStartedAt == null
            ? null
            : Timestamp.fromDate(cooldownStartedAt),
      },
    );
  }

  @override
  Future<Challenge> createGodChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
    required DateTime proposedDate,
  }) {
    ChallengeRules.validateGodPlacement(
      requestedAt: createdAt,
      proposedDate: proposedDate,
    );
    return _create(
      challengerId: challengerId,
      challengedId: challengedId,
      type: ChallengeType.god,
      createdAt: createdAt,
      proposedDate: proposedDate,
    );
  }

  Future<Challenge> _create({
    required String challengerId,
    required String challengedId,
    required ChallengeType type,
    required DateTime createdAt,
    required DateTime? proposedDate,
    Map<String, Object?> extra = const {},
  }) async {
    final reference = _firestore.collection('challenges').doc();
    await reference.set({
      'challengerId': challengerId,
      'challengedId': challengedId,
      'type': type.name,
      'status': ChallengeStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'proposedDate': proposedDate == null
          ? null
          : Timestamp.fromDate(proposedDate),
      ...extra,
    });
    return getChallenge(reference.id);
  }

  @override
  Future<Challenge> respondToChallenge({
    required String challengeId,
    required String respondentId,
    required ChallengeStatus response,
    DateTime? respondedAt,
    DateTime? alternativeDate,
  }) async {
    final challenge = await getChallenge(challengeId);
    final now = respondedAt ?? DateTime.now();
    if (challenge.status == ChallengeStatus.alternativeDateProposed) {
      if (challenge.challengerId != respondentId) {
        throw StateError('Only the challenger can answer a proposed date.');
      }
      if (response != ChallengeStatus.accepted &&
          response != ChallengeStatus.rejected) {
        throw StateError('Choose whether to accept the proposed date.');
      }
    } else {
      if (challenge.challengedId != respondentId) {
        throw StateError('Only the challenged player can respond.');
      }
      if (challenge.status == ChallengeStatus.pending) {
        ChallengeRules.validateSameDayResponse(
          requestedAt: challenge.createdAt,
          respondedAt: now,
        );
      }
    }
    if (response == ChallengeStatus.alternativeDateProposed) {
      if (alternativeDate == null || challenge.proposedDate == null) {
        throw ArgumentError('Choose an alternative match date.');
      }
      ChallengeRules.validateAlternativeDate(
        requestedAt: challenge.createdAt,
        proposedDate: challenge.proposedDate!,
        alternativeDate: alternativeDate,
      );
    }
    challenge.transitionTo(response);
    final updates = <String, Object?>{
      'status': response.name,
      'respondedAt': FieldValue.serverTimestamp(),
    };
    if (response == ChallengeStatus.alternativeDateProposed) {
      updates['alternativeDate'] = Timestamp.fromDate(alternativeDate!);
    } else if (challenge.status == ChallengeStatus.alternativeDateProposed &&
        response == ChallengeStatus.accepted &&
        challenge.alternativeDate != null) {
      updates['proposedDate'] = Timestamp.fromDate(challenge.alternativeDate!);
    }
    await _firestore.collection('challenges').doc(challengeId).update(updates);
    return getChallenge(challengeId);
  }

  @override
  Future<Challenge> completeChallenge({
    required String challengeId,
    required String actorId,
  }) async {
    final challenge = await getChallenge(challengeId);
    if (challenge.challengerId != actorId &&
        challenge.challengedId != actorId) {
      throw StateError('Only a challenge participant can complete it.');
    }
    final updated = challenge.transitionTo(ChallengeStatus.completed);
    await _firestore.collection('challenges').doc(challengeId).update({
      'status': updated.status.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
    return updated;
  }

  Challenge _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => _fromData(document.id, document.data());

  Challenge _fromData(String id, Map<String, dynamic> data) {
    return Challenge(
      id: id,
      challengerId: data['challengerId'] as String,
      challengedId: data['challengedId'] as String,
      type: ChallengeType.values.byName(data['type'] as String),
      status: ChallengeStatus.values.byName(data['status'] as String),
      createdAt: _dateFrom(data['createdAt']) ?? DateTime.now(),
      proposedDate: _dateFrom(data['proposedDate']),
      alternativeDate: _dateFrom(data['alternativeDate']),
    );
  }

  DateTime? _dateFrom(Object? value) => value is Timestamp
      ? value.toDate()
      : value is String
      ? DateTime.tryParse(value)
      : null;
}
