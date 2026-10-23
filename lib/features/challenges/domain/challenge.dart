enum ChallengeType { normal, god }

enum ChallengeStatus {
  pending,
  accepted,
  rejected,
  alternativeDateProposed,
  completed,
  expired,
}

class Challenge {
  const Challenge({
    required this.id,
    required this.challengerId,
    required this.challengedId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.proposedDate,
  }) : assert(id != ''),
       assert(challengerId != ''),
       assert(challengedId != ''),
       assert(challengerId != challengedId);

  final String id;
  final String challengerId;
  final String challengedId;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime? proposedDate;

  Challenge transitionTo(ChallengeStatus nextStatus) {
    if (!_allowedTransitions[status]!.contains(nextStatus)) {
      throw StateError(
        'Cannot transition challenge from $status to $nextStatus.',
      );
    }

    return Challenge(
      id: id,
      challengerId: challengerId,
      challengedId: challengedId,
      type: type,
      status: nextStatus,
      createdAt: createdAt,
      proposedDate: proposedDate,
    );
  }

  static const _allowedTransitions = <ChallengeStatus, Set<ChallengeStatus>>{
    ChallengeStatus.pending: {
      ChallengeStatus.accepted,
      ChallengeStatus.rejected,
      ChallengeStatus.alternativeDateProposed,
      ChallengeStatus.expired,
    },
    ChallengeStatus.alternativeDateProposed: {
      ChallengeStatus.accepted,
      ChallengeStatus.rejected,
      ChallengeStatus.expired,
    },
    ChallengeStatus.accepted: {ChallengeStatus.completed},
    ChallengeStatus.rejected: {},
    ChallengeStatus.completed: {},
    ChallengeStatus.expired: {},
  };
}
