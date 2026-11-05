class MatchScore {
  const MatchScore._();

  static bool isValid(String score) => _parse(score) != null;

  static bool challengerWon(String score) {
    final setScores = _parse(score);
    if (setScores == null) {
      throw const FormatException(
        'Use scores such as 6-4, 6-3 with one or more sets.',
      );
    }

    var challengerSets = 0;
    var opponentSets = 0;
    for (final (challengerGames, opponentGames) in setScores) {
      if (challengerGames > opponentGames) {
        challengerSets++;
      } else {
        opponentSets++;
      }
    }
    if (challengerSets == opponentSets) {
      throw const FormatException('The score does not have a clear winner.');
    }
    return challengerSets > opponentSets;
  }

  static List<(int, int)>? _parse(String score) {
    final sets = score.trim().split(',');
    if (sets.isEmpty || sets.any((set) => set.trim().isEmpty)) {
      return null;
    }

    final scores = <(int, int)>[];
    for (final set in sets) {
      final parts = set.trim().split('-');
      if (parts.length != 2) {
        return null;
      }
      final challengerGames = int.tryParse(parts[0]);
      final opponentGames = int.tryParse(parts[1]);
      if (challengerGames == null ||
          opponentGames == null ||
          challengerGames < 0 ||
          opponentGames < 0 ||
          challengerGames == opponentGames) {
        return null;
      }
      scores.add((challengerGames, opponentGames));
    }
    return scores;
  }
}
