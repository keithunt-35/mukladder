import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/challenge_repository.dart';
import '../data/in_memory_challenge_repository.dart';
import '../domain/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return InMemoryChallengeRepository(
    challenges: [
      Challenge(
        id: 'challenge-incoming-1',
        challengerId: 'player-2',
        challengedId: 'demo-player-1',
        type: ChallengeType.normal,
        status: ChallengeStatus.pending,
        createdAt: DateTime(2026, 10, 23),
      ),
    ],
  );
});

final challengesProvider = FutureProvider<List<Challenge>>((ref) {
  return ref.watch(challengeRepositoryProvider).getChallenges();
});

final challengeCreationProvider =
    FutureProvider.family<Challenge, ChallengeRequest>((ref, request) {
      return ref
          .watch(challengeRepositoryProvider)
          .createNormalChallenge(
            challengerId: request.challengerId,
            challengedId: request.challengedId,
            createdAt: request.createdAt,
          );
    });

final challengeResponseProvider =
    FutureProvider.family<Challenge, ChallengeResponseRequest>((ref, request) {
      return ref
          .watch(challengeRepositoryProvider)
          .respondToChallenge(
            challengeId: request.challengeId,
            respondentId: request.respondentId,
            response: request.response,
          );
    });

class ChallengeRequest {
  const ChallengeRequest({
    required this.challengerId,
    required this.challengedId,
    required this.createdAt,
  });

  final String challengerId;
  final String challengedId;
  final DateTime createdAt;
}

class ChallengeResponseRequest {
  const ChallengeResponseRequest({
    required this.challengeId,
    required this.respondentId,
    required this.response,
  });

  final String challengeId;
  final String respondentId;
  final ChallengeStatus response;
}
