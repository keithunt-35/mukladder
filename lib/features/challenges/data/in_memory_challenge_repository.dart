import '../domain/challenge.dart';
import '../domain/challenge_rules.dart';
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
    int? challengerPosition,
    int? challengedPosition,
    DateTime? proposedDate,
    DateTime? cooldownStartedAt,
  }) async {
    if (challengerId == challengedId) {
      throw ArgumentError('A player cannot challenge themselves.');
    }
    if (cooldownStartedAt != null) {
      ChallengeRules.validateTwoDayCooldown(
        cooldownStartedAt: cooldownStartedAt,
        requestedAt: createdAt,
      );
    }
    if (challengerPosition != null && challengedPosition != null) {
      ChallengeRules.validateNormalPlacement(
        challengerPosition: challengerPosition,
        challengedPosition: challengedPosition,
        requestedAt: createdAt,
        proposedDate: proposedDate,
      );
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
      proposedDate: proposedDate,
    );
    _challenges.add(challenge);
    return challenge;
  }

  @override
  Future<Challenge> createGodChallenge({
    required String challengerId,
    required String challengedId,
    required DateTime createdAt,
    required DateTime proposedDate,
  }) async {
    if (challengerId == challengedId) {
      throw ArgumentError('A player cannot challenge themselves.');
    }
    ChallengeRules.validateGodPlacement(
      requestedAt: createdAt,
      proposedDate: proposedDate,
    );
    final duplicateExists = _challenges.any(
      (challenge) =>
          challenge.challengerId == challengerId &&
          challenge.challengedId == challengedId &&
          challenge.type == ChallengeType.god &&
          challenge.status == ChallengeStatus.pending,
    );
    if (duplicateExists) {
      throw StateError('A pending G.O.D. challenge already exists.');
    }
    final challenge = Challenge(
      id: 'challenge-${_challenges.length + 1}',
      challengerId: challengerId,
      challengedId: challengedId,
      type: ChallengeType.god,
      status: ChallengeStatus.pending,
      createdAt: createdAt,
      proposedDate: proposedDate,
    );
    _challenges.add(challenge);
    return challenge;
  }

  @override
  Future<Challenge> respondToChallenge({
    required String challengeId,
    required String respondentId,
    required ChallengeStatus response,
    DateTime? respondedAt,
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
    if (respondedAt != null) {
      ChallengeRules.validateSameDayResponse(
        requestedAt: challenge.createdAt,
        respondedAt: respondedAt,
      );
    }

    final updatedChallenge = challenge.transitionTo(response);
    _challenges[index] = updatedChallenge;
    return updatedChallenge;
  }

  @override
  Future<Challenge> completeChallenge({
    required String challengeId,
    required String actorId,
  }) async {
    final index = _challenges.indexWhere(
      (challenge) => challenge.id == challengeId,
    );
    if (index == -1) {
      throw StateError('Challenge was not found.');
    }

    final challenge = _challenges[index];
    if (challenge.challengerId != actorId &&
        challenge.challengedId != actorId) {
      throw StateError('Only challenge participants can complete a challenge.');
    }

    final updatedChallenge = challenge.transitionTo(ChallengeStatus.completed);
    _challenges[index] = updatedChallenge;
    return updatedChallenge;
  }
}
