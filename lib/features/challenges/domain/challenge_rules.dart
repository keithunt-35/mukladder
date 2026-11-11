class ChallengeRules {
  const ChallengeRules._();

  static DateTime toKampalaTime(DateTime date) {
    return date.toUtc().add(const Duration(hours: 3));
  }

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

    final localRequested = toKampalaTime(requestedAt);
    if (localRequested.hour < 6 || localRequested.hour >= 20) {
      throw ArgumentError(
        'Challenges must be placed between 6:00 a.m. and 8:00 p.m.',
      );
    }
    if (proposedDate == null) {
      throw ArgumentError('A challenge must include a proposed match date.');
    }
    final localProposed = toKampalaTime(proposedDate);
    final requestedDay = DateTime(
      localRequested.year,
      localRequested.month,
      localRequested.day,
    );
    final proposedDay = DateTime(
      localProposed.year,
      localProposed.month,
      localProposed.day,
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
    final localRequested = toKampalaTime(requestedAt);
    if (localRequested.hour < 6 || localRequested.hour >= 20) {
      throw ArgumentError(
        'Challenges must be placed between 6:00 a.m. and 8:00 p.m.',
      );
    }
    final localProposed = toKampalaTime(proposedDate);
    final requestedDay = DateTime(
      localRequested.year,
      localRequested.month,
      localRequested.day,
    );
    final proposedDay = DateTime(
      localProposed.year,
      localProposed.month,
      localProposed.day,
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
    final localRequested = toKampalaTime(requestedAt);
    final localResponded = toKampalaTime(respondedAt);
    final requestedDay = DateTime(
      localRequested.year,
      localRequested.month,
      localRequested.day,
    );
    final responseDay = DateTime(
      localResponded.year,
      localResponded.month,
      localResponded.day,
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
    final localRequested = toKampalaTime(requestedAt);
    final localProposed = toKampalaTime(proposedDate);
    final localAlternative = toKampalaTime(alternativeDate);
    final requestDay = DateTime(
      localRequested.year,
      localRequested.month,
      localRequested.day,
    );
    final alternativeDay = DateTime(
      localAlternative.year,
      localAlternative.month,
      localAlternative.day,
    );
    final currentDay = DateTime(
      localProposed.year,
      localProposed.month,
      localProposed.day,
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
    final localMatch = toKampalaTime(matchDate);
    final localSubmitted = toKampalaTime(submittedAt);
    final matchDay = DateTime(
      localMatch.year,
      localMatch.month,
      localMatch.day,
    );
    final submissionDay = DateTime(
      localSubmitted.year,
      localSubmitted.month,
      localSubmitted.day,
    );
    if (submissionDay != matchDay || localSubmitted.hour >= 20) {
      throw StateError(
        'Completed results must be received on the match day before 8:00 p.m.',
      );
    }
  }

  static void validateTwoDayCooldown({
    required DateTime cooldownStartedAt,
    required DateTime requestedAt,
  }) {
    final localCooldown = toKampalaTime(cooldownStartedAt);
    final localRequested = toKampalaTime(requestedAt);
    if (localRequested.difference(localCooldown).inDays < 2) {
      throw StateError(
        'The challenger must wait two days before placing another challenge.',
      );
    }
  }
}
