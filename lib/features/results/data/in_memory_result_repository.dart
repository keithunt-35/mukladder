import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge.dart';
import '../../audit/data/audit_repository.dart';
import '../../audit/data/in_memory_audit_repository.dart';
import '../../challenges/domain/challenge_rules.dart';
import '../domain/match_result.dart';
import '../domain/match_score.dart';
import 'result_repository.dart';

class InMemoryResultRepository implements ResultRepository {
  InMemoryResultRepository({
    required this.challengeRepository,
    AuditRepository? auditRepository,
  }) : auditRepository = auditRepository ?? InMemoryAuditRepository();

  final ChallengeRepository challengeRepository;
  final AuditRepository auditRepository;
  final List<MatchResult> _results = [];

  @override
  Future<List<MatchResult>> getResults() async {
    return List.unmodifiable(_results);
  }

  @override
  Future<MatchResult> submitResult({
    required String challengeId,
    required String submittedBy,
    required String score,
    required DateTime submittedAt,
  }) async {
    final challenge = await challengeRepository.getChallenge(challengeId);
    if (challenge.status != ChallengeStatus.accepted) {
      throw StateError(
        'Results can only be submitted for accepted challenges.',
      );
    }
    if (submittedBy != challenge.challengerId &&
        submittedBy != challenge.challengedId) {
      throw StateError('Only challenge participants can submit a result.');
    }
    if (challenge.proposedDate != null) {
      ChallengeRules.validateResultSubmission(
        matchDate: challenge.proposedDate!,
        submittedAt: submittedAt,
      );
    }
    if (!MatchScore.isValid(score)) {
      throw FormatException(
        'Use scores such as 6-4, 6-3 with one or more sets.',
      );
    }
    if (_results.any((result) => result.challengeId == challengeId)) {
      throw StateError(
        'A result has already been submitted for this challenge.',
      );
    }

    final result = MatchResult(
      id: 'result-${_results.length + 1}',
      challengeId: challengeId,
      submittedBy: submittedBy,
      score: score.trim(),
      status: ResultStatus.submitted,
      submittedAt: submittedAt,
    );
    _results.add(result);
    await auditRepository.recordEvent(
      actorId: submittedBy,
      eventType: 'result_submitted',
      entityType: 'result',
      entityId: result.id,
      before: null,
      after: result.status.name,
      createdAt: submittedAt,
    );
    return result;
  }

  @override
  Future<MatchResult> transitionResult({
    required String resultId,
    required String actorId,
    required ResultStatus status,
  }) async {
    final index = _results.indexWhere((result) => result.id == resultId);
    if (index == -1) {
      throw StateError('Result was not found.');
    }

    final result = _results[index];
    final challenge = await challengeRepository.getChallenge(
      result.challengeId,
    );
    if (actorId != challenge.challengerId &&
        actorId != challenge.challengedId) {
      throw StateError('Only challenge participants can review a result.');
    }
    if (actorId == result.submittedBy) {
      throw StateError('The result submitter cannot confirm their own score.');
    }

    final updatedResult = result.transitionTo(status);
    _results[index] = updatedResult;
    if (status == ResultStatus.confirmed) {
      await challengeRepository.completeChallenge(
        challengeId: result.challengeId,
        actorId: actorId,
      );
    }
    await auditRepository.recordEvent(
      actorId: actorId,
      eventType: 'result_${status.name}',
      entityType: 'result',
      entityId: result.id,
      before: result.status.name,
      after: updatedResult.status.name,
      createdAt: DateTime.now(),
    );
    return updatedResult;
  }

  static bool isValidScore(String score) => MatchScore.isValid(score);
}
