import '../domain/challenge.dart';

abstract interface class ChallengeRepository {
  Future<List<Challenge>> getChallenges();

  Future<Challenge> getChallenge(String challengeId);

  Future<Challenge> createNormalChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
    int? challengerPosition,
    int? challengedPosition,
    DateTime? proposedDate,
    DateTime? cooldownStartedAt,
  });

  Future<Challenge> createGodChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
    required DateTime proposedDate,
  });

  Future<Challenge> respondToChallenge({
    required String challengeId,
    required String respondentId,
    required ChallengeStatus response,
    DateTime? respondedAt,
    DateTime? alternativeDate,
  });

  Future<Challenge> completeChallenge({
    required String challengeId,
    required String actorId,
  });
}
