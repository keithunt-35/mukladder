class ChallengeRules {
  const ChallengeRules._();

  static void validateNormalPlacement({
    required int challengerPosition,
    required int challengedPosition,
    required DateTime requestedAt,
    DateTime? proposedDate,
  }) {
    if (challengedPosition >= challengerPosition) {
      throw ArgumentError(
        'A challenge must target a player ranked above the challenger.',
      );
    }

    if (challengerPosition - challengedPosition > 4) {
      throw ArgumentError(
        'A Normal challenge may target at most four positions above.',
      );
    }
    if (requestedAt.hour < 6 || requestedAt.hour >= 20) {
      throw ArgumentError(
        'Challenges must be placed between 6:00 a.m. and 8:00 p.m.',
      );
    }
    if (proposedDate == null) {
      throw ArgumentError('A challenge must include a proposed match date.');
    }
    final requestedDay = DateTime(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );
    final proposedDay = DateTime(
      proposedDate.year,
      proposedDate.month,
      proposedDate.day,
    );
    final daysAhead = proposedDay.difference(requestedDay).inDays;
    if (daysAhead < 1 || daysAhead > 3) {
      throw ArgumentError(
        'A match must be scheduled from the next day up to three days ahead.',
      );
    }
  }

  static void validateGodPlacement({
    required DateTime requestedAt,
    required DateTime proposedDate,
  }) {
    if (requestedAt.hour < 6 || requestedAt.hour >= 20) {
      throw ArgumentError(
        'Challenges must be placed between 6:00 a.m. and 8:00 p.m.',
      );
    }
    final requestedDay = DateTime(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );
    final proposedDay = DateTime(
      proposedDate.year,
      proposedDate.month,
      proposedDate.day,
    );
    final daysAhead = proposedDay.difference(requestedDay).inDays;
    if (daysAhead < 1 || daysAhead > 3) {
      throw ArgumentError(
        'A match must be scheduled from the next day up to three days ahead.',
      );
    }
  }

  static void validateSameDayResponse({
    required DateTime requestedAt,
    required DateTime respondedAt,
  }) {
    final requestedDay = DateTime(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );
    final responseDay = DateTime(
      respondedAt.year,
      respondedAt.month,
      respondedAt.day,
    );
    if (responseDay != requestedDay) {
      throw StateError('A challenge must be answered on the placement day.');
    }
  }

  static void validateAlternativeDate({
    required DateTime requestedAt,
    required DateTime proposedDate,
    required DateTime alternativeDate,
  }) {
    final requestDay = DateTime(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );
    final alternativeDay = DateTime(
      alternativeDate.year,
      alternativeDate.month,
      alternativeDate.day,
    );
    final currentDay = DateTime(
      proposedDate.year,
      proposedDate.month,
      proposedDate.day,
    );
    final daysAhead = alternativeDay.difference(requestDay).inDays;
    if (daysAhead < 1 || daysAhead > 3 || alternativeDay == currentDay) {
      throw ArgumentError(
        'Choose a different match date within three days of the challenge.',
      );
    }
  }

  static void validateResultSubmission({
    required DateTime matchDate,
    required DateTime submittedAt,
  }) {
    final matchDay = DateTime(matchDate.year, matchDate.month, matchDate.day);
    final submissionDay = DateTime(
      submittedAt.year,
      submittedAt.month,
      submittedAt.day,
    );
    if (submissionDay != matchDay || submittedAt.hour >= 20) {
      throw StateError(
        'Completed results must be received on the match day before 8:00 p.m.',
      );
    }
  }

  static void validateTwoDayCooldown({
    required DateTime cooldownStartedAt,
    required DateTime requestedAt,
  }) {
    if (requestedAt.difference(cooldownStartedAt).inDays < 2) {
      throw StateError(
        'The challenger must wait two days before placing another challenge.',
      );
    }
  }
}
