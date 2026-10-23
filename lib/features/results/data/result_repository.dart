import '../domain/match_result.dart';

abstract interface class ResultRepository {
  Future<List<MatchResult>> getResults();

  Future<MatchResult> submitResult({
    required String challengeId,
    required String submittedBy,
    required String score,
    required DateTime submittedAt,
  });

  Future<MatchResult> transitionResult({
    required String resultId,
    required String actorId,
    required ResultStatus status,
  });
}
