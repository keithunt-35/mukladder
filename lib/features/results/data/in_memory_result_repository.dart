import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge.dart';
import '../domain/match_result.dart';
import 'result_repository.dart';

class InMemoryResultRepository implements ResultRepository {
  InMemoryResultRepository({required this.challengeRepository});

  final ChallengeRepository challengeRepository;
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
    if (!isValidScore(score)) {
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

    final updatedResult = result.transitionTo(status);
    _results[index] = updatedResult;
    if (status == ResultStatus.confirmed) {
      await challengeRepository.completeChallenge(
        challengeId: result.challengeId,
        actorId: actorId,
      );
    }
    return updatedResult;
  }

  static bool isValidScore(String score) {
    final parts = score.trim().split(',').map((set) => set.trim()).toList();
    if (parts.isEmpty || parts.any((set) => !_setPattern.hasMatch(set))) {
      return false;
    }
    return true;
  }

  static final _setPattern = RegExp(r'^\d+-\d+$');
}
