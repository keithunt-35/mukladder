import '../../challenges/domain/challenge.dart';
import '../../results/domain/match_result.dart';
import 'ranking_entry.dart';

/// Applies the supplied MUK Ladder Rules ranking outcomes locally.
///
/// The production implementation must apply the same outcomes in a trusted
/// transaction. This calculator is retained for deterministic demo behavior.
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
      final challengerIndex = ranking.indexWhere(
        (entry) => entry.player.id == challenge.challengerId,
      );
      final challengedIndex = ranking.indexWhere(
        (entry) => entry.player.id == challenge.challengedId,
      );
      if (challengerIndex == -1 || challengedIndex == -1) {
        throw StateError('Both result participants must be ranked players.');
      }
      if (_winnerIsChallenger(result.score)) {
        if (challenge.type == ChallengeType.god) {
          final challenger = ranking[challengerIndex];
          ranking[challengerIndex] = ranking[challengedIndex];
          ranking[challengedIndex] = challenger;
        } else if (challengerIndex > challengedIndex) {
          final challenger = ranking.removeAt(challengerIndex);
          ranking.insert(challengedIndex, challenger);
        }
      } else if (challenge.type == ChallengeType.god) {
        final challenger = ranking.removeAt(challengerIndex);
        ranking.add(challenger);
      }
    }

    return [
      for (var index = 0; index < ranking.length; index++)
        RankingEntry(player: ranking[index].player, position: index + 1),
    ];
  }

  static bool _winnerIsChallenger(String score) {
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
    return firstPlayerSets > secondPlayerSets;
  }
}
