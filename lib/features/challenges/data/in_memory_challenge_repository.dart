import '../domain/challenge.dart';
import 'challenge_repository.dart';

class InMemoryChallengeRepository implements ChallengeRepository {
  InMemoryChallengeRepository({Iterable<Challenge> challenges = const []})
    : _challenges = [...challenges];

  final List<Challenge> _challenges;

  @override
  Future<List<Challenge>> getChallenges() async {
    return List.unmodifiable(_challenges);
  }

  @override
  Future<Challenge> getChallenge(String challengeId) async {
    return _challenges.firstWhere(
      (challenge) => challenge.id == challengeId,
      orElse: () => throw StateError('Challenge was not found.'),
    );
  }

  @override
  Future<Challenge> createNormalChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
  }) async {
    if (challengerId == challengedId) {
      throw ArgumentError('A player cannot challenge themselves.');
    }

    final duplicateExists = _challenges.any(
      (challenge) =>
          challenge.challengerId == challengerId &&
          challenge.challengedId == challengedId &&
          challenge.type == ChallengeType.normal &&
          challenge.status == ChallengeStatus.pending,
    );
    if (duplicateExists) {
      throw StateError('A pending challenge already exists for this player.');
    }

    final challenge = Challenge(
      id: 'challenge-${_challenges.length + 1}',
      challengerId: challengerId,
      challengedId: challengedId,
      type: ChallengeType.normal,
      status: ChallengeStatus.pending,
      createdAt: createdAt,
    );
    _challenges.add(challenge);
    return challenge;
  }

  @override
  Future<Challenge> respondToChallenge({
    required String challengeId,
    required String respondentId,
    required ChallengeStatus response,
  }) async {
    final index = _challenges.indexWhere(
      (challenge) => challenge.id == challengeId,
    );
    if (index == -1) {
      throw StateError('Challenge was not found.');
    }

    final challenge = _challenges[index];
    if (challenge.challengedId != respondentId) {
      throw StateError('Only the challenged player can respond.');
    }

    final updatedChallenge = challenge.transitionTo(response);
    _challenges[index] = updatedChallenge;
    return updatedChallenge;
  }
}
