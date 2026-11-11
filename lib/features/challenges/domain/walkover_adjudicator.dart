import '../domain/challenge.dart';

class WalkoverAdjudicator {
  const WalkoverAdjudicator._();

  /// Validates whether a walkover can be claimed for a challenge.
  ///
  /// A walkover may be claimed if the match date has passed without a result
  /// and administrative or participant attendance evidence confirms absence.
  static void validateWalkoverClaim({
    required Challenge challenge,
    required DateTime currentDateTime,
    required bool isClaimantParticipant,
  }) {
    if (!isClaimantParticipant) {
      throw ArgumentError('Only match participants can claim a walkover.');
    }
    if (challenge.status != ChallengeStatus.accepted &&
        challenge.status != ChallengeStatus.alternativeDateProposed) {
      throw StateError('A walkover can only be claimed for an active challenge.');
    }
    if (challenge.proposedDate == null) {
      throw StateError('A challenge must have a scheduled match date to claim a walkover.');
    }

    final matchDay = DateTime(
      challenge.proposedDate!.year,
      challenge.proposedDate!.month,
      challenge.proposedDate!.day,
    );
    final currentDay = DateTime(
      currentDateTime.year,
      currentDateTime.month,
      currentDateTime.day,
    );

    if (currentDay.isBefore(matchDay)) {
      throw StateError('Cannot claim a walkover before the scheduled match date has passed.');
    }
  }
}
