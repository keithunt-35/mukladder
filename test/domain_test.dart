import 'package:flutter_test/flutter_test.dart';
import 'package:mukladder/features/challenges/domain/challenge.dart';
import 'package:mukladder/features/ladder/data/in_memory_ranking_repository.dart';
import 'package:mukladder/features/ladder/domain/ranking_entry.dart';
import 'package:mukladder/features/players/data/in_memory_player_repository.dart';
import 'package:mukladder/features/players/domain/player.dart';
import 'package:mukladder/features/results/domain/match_result.dart';

void main() {
  final player = Player(
    id: 'player-1',
    displayName: 'Demo Player',
    lastActivityAt: DateTime(2026, 10, 23),
  );

  group('domain models', () {
    test('creates a ranking entry with a positive position', () {
      final entry = RankingEntry(player: player, position: 1);

      expect(entry.player.displayName, 'Demo Player');
      expect(entry.position, 1);
    });

    test('allows valid challenge transitions', () {
      final challenge = Challenge(
        id: 'challenge-1',
        challengerId: 'player-1',
        challengedId: 'player-2',
        type: ChallengeType.normal,
        status: ChallengeStatus.pending,
        createdAt: DateTime(2026, 10, 23),
      );

      expect(
        challenge.transitionTo(ChallengeStatus.accepted).status,
        ChallengeStatus.accepted,
      );
    });

    test('rejects invalid challenge transitions', () {
      final challenge = Challenge(
        id: 'challenge-1',
        challengerId: 'player-1',
        challengedId: 'player-2',
        type: ChallengeType.normal,
        status: ChallengeStatus.completed,
        createdAt: DateTime(2026, 10, 23),
      );

      expect(
        () => challenge.transitionTo(ChallengeStatus.pending),
        throwsStateError,
      );
    });

    test('allows result confirmation and rejects duplicate transitions', () {
      final result = MatchResult(
        id: 'result-1',
        challengeId: 'challenge-1',
        submittedBy: 'player-1',
        score: '6-4, 6-3',
        status: ResultStatus.submitted,
        submittedAt: DateTime(2026, 10, 23),
      );

      expect(
        result.transitionTo(ResultStatus.confirmed).status,
        ResultStatus.confirmed,
      );
      expect(
        () => result
            .transitionTo(ResultStatus.confirmed)
            .transitionTo(ResultStatus.disputed),
        throwsStateError,
      );
    });
  });

  group('in-memory repositories', () {
    test('returns player data', () async {
      final repository = InMemoryPlayerRepository(players: [player]);

      expect(await repository.getPlayers(), hasLength(1));
      expect((await repository.getPlayers()).single.id, player.id);
    });

    test('returns an empty ranking when no entries exist', () async {
      final repository = InMemoryRankingRepository();

      expect(await repository.getRanking(), isEmpty);
    });

    test('reports unavailable demo data explicitly', () async {
      final repository = InMemoryPlayerRepository(shouldFail: true);

      expect(repository.getPlayers(), throwsStateError);
    });
  });
}
