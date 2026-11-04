import 'package:flutter_test/flutter_test.dart';
import 'package:mukladder/features/challenges/domain/challenge.dart';
import 'package:mukladder/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:mukladder/features/ladder/data/in_memory_ranking_repository.dart';
import 'package:mukladder/features/ladder/domain/provisional_ranking_calculator.dart';
import 'package:mukladder/features/ladder/domain/ranking_entry.dart';
import 'package:mukladder/features/players/data/in_memory_player_repository.dart';
import 'package:mukladder/features/players/domain/player.dart';
import 'package:mukladder/features/results/domain/match_result.dart';
import 'package:mukladder/features/results/data/in_memory_result_repository.dart';

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

    test('moves the confirmed winner above the loser provisionally', () {
      final challenge = Challenge(
        id: 'challenge-1',
        challengerId: 'player-1',
        challengedId: 'player-2',
        type: ChallengeType.normal,
        status: ChallengeStatus.accepted,
        createdAt: DateTime(2026, 10, 23),
      );
      final result = MatchResult(
        id: 'result-1',
        challengeId: challenge.id,
        submittedBy: challenge.challengerId,
        score: '6-4, 6-3',
        status: ResultStatus.confirmed,
        submittedAt: DateTime(2026, 10, 23),
      );
      final entries = [
        RankingEntry(
          position: 1,
          player: Player(
            id: 'player-2',
            displayName: 'Opponent',
            lastActivityAt: DateTime(2026, 10, 22),
          ),
        ),
        RankingEntry(position: 2, player: player),
      ];

      final updated = const ProvisionalRankingCalculator().calculate(
        entries: entries,
        challenges: [challenge],
        results: [result],
      );

      expect(updated.map((entry) => entry.player.id), ['player-1', 'player-2']);
      expect(updated.map((entry) => entry.position), [1, 2]);
    });

    test('rejects applying the same confirmed result twice', () {
      final challenge = Challenge(
        id: 'challenge-1',
        challengerId: 'player-1',
        challengedId: 'player-2',
        type: ChallengeType.normal,
        status: ChallengeStatus.accepted,
        createdAt: DateTime(2026, 10, 23),
      );
      final result = MatchResult(
        id: 'result-1',
        challengeId: challenge.id,
        submittedBy: challenge.challengerId,
        score: '6-4, 6-3',
        status: ResultStatus.confirmed,
        submittedAt: DateTime(2026, 10, 23),
      );

      expect(
        () => const ProvisionalRankingCalculator().calculate(
          entries: [
            RankingEntry(position: 1, player: player),
            RankingEntry(
              position: 2,
              player: Player(
                id: 'player-2',
                displayName: 'Opponent',
                lastActivityAt: DateTime(2026, 10, 22),
              ),
            ),
          ],
          challenges: [challenge],
          results: [result, result],
        ),
        throwsStateError,
      );
    });
  });

  group('in-memory repositories', () {
    test('creates a pending Normal challenge', () async {
      final repository = InMemoryChallengeRepository();

      final challenge = await repository.createNormalChallenge(
        challengerId: 'player-1',
        challengedId: 'player-2',
        createdAt: DateTime(2026, 10, 23),
      );

      expect(challenge.type, ChallengeType.normal);
      expect(challenge.status, ChallengeStatus.pending);
    });

    test('rejects duplicate pending challenges', () async {
      final repository = InMemoryChallengeRepository();
      final request = (
        challengerId: 'player-1',
        challengedId: 'player-2',
        createdAt: DateTime(2026, 10, 23),
      );
      await repository.createNormalChallenge(
        challengerId: request.challengerId,
        challengedId: request.challengedId,
        createdAt: request.createdAt,
      );

      expect(
        repository.createNormalChallenge(
          challengerId: request.challengerId,
          challengedId: request.challengedId,
          createdAt: request.createdAt,
        ),
        throwsStateError,
      );
    });

    test('rejects self-challenges', () {
      final repository = InMemoryChallengeRepository();

      expect(
        repository.createNormalChallenge(
          challengerId: 'player-1',
          challengedId: 'player-1',
          createdAt: DateTime(2026, 10, 23),
        ),
        throwsArgumentError,
      );
    });

    test('accepts an incoming challenge for the challenged player', () async {
      final repository = InMemoryChallengeRepository(
        challenges: [
          Challenge(
            id: 'challenge-1',
            challengerId: 'player-2',
            challengedId: 'player-1',
            type: ChallengeType.normal,
            status: ChallengeStatus.pending,
            createdAt: DateTime(2026, 10, 23),
          ),
        ],
      );

      final response = await repository.respondToChallenge(
        challengeId: 'challenge-1',
        respondentId: 'player-1',
        response: ChallengeStatus.accepted,
      );

      expect(response.status, ChallengeStatus.accepted);
    });

    test('rejects repeated challenge responses', () async {
      final repository = InMemoryChallengeRepository(
        challenges: [
          Challenge(
            id: 'challenge-1',
            challengerId: 'player-2',
            challengedId: 'player-1',
            type: ChallengeType.normal,
            status: ChallengeStatus.pending,
            createdAt: DateTime(2026, 10, 23),
          ),
        ],
      );
      await repository.respondToChallenge(
        challengeId: 'challenge-1',
        respondentId: 'player-1',
        response: ChallengeStatus.accepted,
      );

      expect(
        repository.respondToChallenge(
          challengeId: 'challenge-1',
          respondentId: 'player-1',
          response: ChallengeStatus.rejected,
        ),
        throwsStateError,
      );
    });

    test('submits and confirms a result for an accepted challenge', () async {
      final challengeRepository = InMemoryChallengeRepository(
        challenges: [
          Challenge(
            id: 'challenge-1',
            challengerId: 'player-2',
            challengedId: 'player-1',
            type: ChallengeType.normal,
            status: ChallengeStatus.accepted,
            createdAt: DateTime(2026, 10, 23),
          ),
        ],
      );
      final repository = InMemoryResultRepository(
        challengeRepository: challengeRepository,
      );

      final result = await repository.submitResult(
        challengeId: 'challenge-1',
        submittedBy: 'player-1',
        score: '6-4, 6-3',
        submittedAt: DateTime(2026, 10, 23),
      );
      final confirmed = await repository.transitionResult(
        resultId: result.id,
        actorId: 'player-2',
        status: ResultStatus.confirmed,
      );

      expect(confirmed.status, ResultStatus.confirmed);
    });

    test('rejects invalid and duplicate results', () async {
      final challengeRepository = InMemoryChallengeRepository(
        challenges: [
          Challenge(
            id: 'challenge-1',
            challengerId: 'player-2',
            challengedId: 'player-1',
            type: ChallengeType.normal,
            status: ChallengeStatus.accepted,
            createdAt: DateTime(2026, 10, 23),
          ),
        ],
      );
      final repository = InMemoryResultRepository(
        challengeRepository: challengeRepository,
      );

      expect(
        repository.submitResult(
          challengeId: 'challenge-1',
          submittedBy: 'player-1',
          score: 'invalid',
          submittedAt: DateTime(2026, 10, 23),
        ),
        throwsFormatException,
      );
      await repository.submitResult(
        challengeId: 'challenge-1',
        submittedBy: 'player-1',
        score: '6-4',
        submittedAt: DateTime(2026, 10, 23),
      );
      expect(
        repository.submitResult(
          challengeId: 'challenge-1',
          submittedBy: 'player-2',
          score: '6-2',
          submittedAt: DateTime(2026, 10, 23),
        ),
        throwsStateError,
      );
    });

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
