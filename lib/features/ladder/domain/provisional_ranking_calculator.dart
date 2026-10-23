import '../../challenges/domain/challenge.dart';
import '../../results/domain/match_result.dart';
import 'ranking_entry.dart';

/// Applies the temporary local ranking policy used by the demo.
///
/// The official MUK Ladder movement algorithm is still unavailable. This
/// policy moves a confirmed-result winner immediately above the loser and
/// preserves the relative order of every other player.
class ProvisionalRankingCalculator {
  const ProvisionalRankingCalculator();

  List<RankingEntry> calculate({
    required Iterable<RankingEntry> entries,
    required Iterable<Challenge> challenges,
    required Iterable<MatchResult> results,
  }) {
    final ranking = entries.toList();
    final challengeById = {
      for (final challenge in challenges) challenge.id: challenge,
    };
    final appliedResultIds = <String>{};

    for (final result in results) {
      if (result.status != ResultStatus.confirmed) {
        continue;
      }
      if (!appliedResultIds.add(result.id)) {
        throw StateError('A confirmed result cannot be applied twice.');
      }

      final challenge = challengeById[result.challengeId];
      if (challenge == null) {
        throw StateError(
          'The challenge for result ${result.id} was not found.',
        );
      }
      final winnerId = _winnerId(result.score, challenge);
      final loserId = winnerId == challenge.challengerId
          ? challenge.challengedId
          : challenge.challengerId;

      final winnerIndex = ranking.indexWhere(
        (entry) => entry.player.id == winnerId,
      );
      final loserIndex = ranking.indexWhere(
        (entry) => entry.player.id == loserId,
      );
      if (winnerIndex == -1 || loserIndex == -1) {
        throw StateError('Both result participants must be ranked players.');
      }
      if (winnerIndex > loserIndex) {
        final winner = ranking.removeAt(winnerIndex);
        ranking.insert(loserIndex, winner);
      }
    }

    return [
      for (var index = 0; index < ranking.length; index++)
        RankingEntry(player: ranking[index].player, position: index + 1),
    ];
  }

  static String _winnerId(String score, Challenge challenge) {
    var firstPlayerSets = 0;
    var secondPlayerSets = 0;
    for (final setScore in score.split(',')) {
      final parts = setScore.trim().split('-');
      if (parts.length != 2) {
        throw FormatException('The confirmed score has an invalid format.');
      }
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      if (first == null ||
          second == null ||
          first < 0 ||
          second < 0 ||
          first == second) {
        throw FormatException('The confirmed score has no clear winner.');
      }
      if (first > second) {
        firstPlayerSets++;
      } else {
        secondPlayerSets++;
      }
    }
    if (firstPlayerSets == secondPlayerSets) {
      throw FormatException('The confirmed score has no clear winner.');
    }
    return firstPlayerSets > secondPlayerSets
        ? challenge.challengerId
        : challenge.challengedId;
  }
}
