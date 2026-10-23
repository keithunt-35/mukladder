enum ResultStatus { submitted, confirmed, disputed }

class MatchResult {
  const MatchResult({
    required this.id,
    required this.challengeId,
    required this.submittedBy,
    required this.score,
    required this.status,
    required this.submittedAt,
  }) : assert(id != ''),
       assert(challengeId != ''),
       assert(submittedBy != ''),
       assert(score != '');

  final String id;
  final String challengeId;
  final String submittedBy;
  final String score;
  final ResultStatus status;
  final DateTime submittedAt;

  MatchResult transitionTo(ResultStatus nextStatus) {
    if (!_allowedTransitions[status]!.contains(nextStatus)) {
      throw StateError('Cannot transition result from $status to $nextStatus.');
    }

    return MatchResult(
      id: id,
      challengeId: challengeId,
      submittedBy: submittedBy,
      score: score,
      status: nextStatus,
      submittedAt: submittedAt,
    );
  }

  static const _allowedTransitions = <ResultStatus, Set<ResultStatus>>{
    ResultStatus.submitted: {ResultStatus.confirmed, ResultStatus.disputed},
    ResultStatus.confirmed: {},
    ResultStatus.disputed: {},
  };
}
