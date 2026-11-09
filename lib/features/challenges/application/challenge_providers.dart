import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../data/challenge_repository.dart';
import '../data/firestore_challenge_repository.dart';
import '../data/in_memory_challenge_repository.dart';
import '../domain/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  if (defaultTargetPlatform != TargetPlatform.android) {
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
  }
  return FirestoreChallengeRepository();
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
            challengerPosition: request.challengerPosition,
            challengedPosition: request.challengedPosition,
            proposedDate: request.proposedDate,
            cooldownStartedAt: request.cooldownStartedAt,
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
            respondedAt: request.respondedAt,
          );
    });

final godChallengeCreationProvider =
    FutureProvider.family<Challenge, GodChallengeRequest>((ref, request) {
      return ref
          .watch(challengeRepositoryProvider)
          .createGodChallenge(
            challengerId: request.challengerId,
            challengedId: request.challengedId,
            createdAt: request.createdAt,
            proposedDate: request.proposedDate,
          );
    });

class ChallengeRequest {
  const ChallengeRequest({
    required this.challengerId,
    required this.challengedId,
    required this.createdAt,
    this.challengerPosition,
    this.challengedPosition,
    this.proposedDate,
    this.cooldownStartedAt,
  });

  final String challengerId;
  final String challengedId;
  final DateTime createdAt;
  final int? challengerPosition;
  final int? challengedPosition;
  final DateTime? proposedDate;
  final DateTime? cooldownStartedAt;
}

class ChallengeResponseRequest {
  const ChallengeResponseRequest({
    required this.challengeId,
    required this.respondentId,
    required this.response,
    this.respondedAt,
  });

  final String challengeId;
  final String respondentId;
  final ChallengeStatus response;
  final DateTime? respondedAt;
}

class GodChallengeRequest {
  const GodChallengeRequest({
    required this.challengerId,
    required this.challengedId,
    required this.createdAt,
    required this.proposedDate,
  });

  final String challengerId;
  final String challengedId;
  final DateTime createdAt;
  final DateTime proposedDate;
}
