import '../domain/challenge.dart';

abstract interface class ChallengeRepository {
  Future<List<Challenge>> getChallenges();

  Future<Challenge> getChallenge(String challengeId);

  Future<Challenge> createNormalChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
  });

  Future<Challenge> respondToChallenge({
    required String challengeId,
    required String respondentId,
    required ChallengeStatus response,
  });
}
