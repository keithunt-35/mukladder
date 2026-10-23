import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../challenges/application/challenge_providers.dart';
import '../data/in_memory_result_repository.dart';
import '../data/result_repository.dart';
import '../domain/match_result.dart';

final resultRepositoryProvider = Provider<ResultRepository>((ref) {
  return InMemoryResultRepository(
    challengeRepository: ref.watch(challengeRepositoryProvider),
  );
});

final resultsProvider = FutureProvider<List<MatchResult>>((ref) {
  return ref.watch(resultRepositoryProvider).getResults();
});

final resultSubmissionProvider =
    FutureProvider.family<MatchResult, ResultSubmissionRequest>((ref, request) {
      return ref
          .watch(resultRepositoryProvider)
          .submitResult(
            challengeId: request.challengeId,
            submittedBy: request.submittedBy,
            score: request.score,
            submittedAt: request.submittedAt,
          );
    });

final resultTransitionProvider =
    FutureProvider.family<MatchResult, ResultTransitionRequest>((ref, request) {
      return ref
          .watch(resultRepositoryProvider)
          .transitionResult(
            resultId: request.resultId,
            actorId: request.actorId,
            status: request.status,
          );
    });

class ResultSubmissionRequest {
  const ResultSubmissionRequest({
    required this.challengeId,
    required this.submittedBy,
    required this.score,
    required this.submittedAt,
  });

  final String challengeId;
  final String submittedBy;
  final String score;
  final DateTime submittedAt;
}

class ResultTransitionRequest {
  const ResultTransitionRequest({
    required this.resultId,
    required this.actorId,
    required this.status,
  });

  final String resultId;
  final String actorId;
  final ResultStatus status;
}
