import '../domain/match_result.dart';

abstract interface class ResultRepository {
  Future<List<MatchResult>> getResults();

  /// Real-time stream of results for challenges the signed-in user participates in.
  Stream<List<MatchResult>> watchResults();

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
