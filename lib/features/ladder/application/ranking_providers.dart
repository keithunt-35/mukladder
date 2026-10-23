import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../players/domain/player.dart';
import '../data/in_memory_ranking_repository.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return InMemoryRankingRepository(entries: demoRankingEntries);
});

final rankingProvider = FutureProvider<List<RankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).getRanking();
});

// The email provides positions but not per-player activity timestamps. The
// date below identifies the source snapshot rather than claiming a match date.
final demoRankingEntries = <RankingEntry>[
  RankingEntry(
    position: 1,
    player: Player(
      id: 'player-1',
      displayName: 'Tayebwa Louis',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 2,
    player: Player(
      id: 'player-2',
      displayName: 'Ahimbisibwe Kevin',
      lastActivityAt: DateTime(2026, 10, 22),
    ),
  ),
  RankingEntry(
    position: 3,
    player: Player(
      id: 'player-3',
      displayName: 'Wanale Fredrick',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 4,
    player: Player(
      id: 'player-4',
      displayName: 'Akolamazima Timothy',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 5,
    player: Player(
      id: 'player-5',
      displayName: 'Lwanga David',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 6,
    player: Player(
      id: 'player-6',
      displayName: 'Edrine Sennungi',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 7,
    player: Player(
      id: 'player-7',
      displayName: 'Sembatya Ivan',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 8,
    player: Player(
      id: 'player-8',
      displayName: 'Matsiko Bob Ethan',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 9,
    player: Player(
      id: 'player-9',
      displayName: 'Andrew Lutwama',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 10,
    player: Player(
      id: 'player-10',
      displayName: 'Ageimo Paul',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 11,
    player: Player(
      id: 'player-11',
      displayName: 'Horeb Rukiri',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 12,
    player: Player(
      id: 'player-12',
      displayName: 'Kitandwe Emmanuel',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 13,
    player: Player(
      id: 'player-13',
      displayName: 'Oryada Andrew Jackson',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 14,
    player: Player(
      id: 'player-14',
      displayName: 'Ambrose Agumenaitwe',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 15,
    player: Player(
      id: 'player-15',
      displayName: 'Kalega William',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 16,
    player: Player(
      id: 'player-16',
      displayName: 'Kaweewo Francis',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 17,
    player: Player(
      id: 'player-17',
      displayName: 'Wambuza John',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 18,
    player: Player(
      id: 'player-18',
      displayName: 'Kibirige Dean',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 19,
    player: Player(
      id: 'player-19',
      displayName: 'Mugenyi Kevin',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 20,
    player: Player(
      id: 'player-20',
      displayName: 'Mpomba Matthew',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 21,
    player: Player(
      id: 'player-21',
      displayName: 'Dr. Aldar Borisov',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 22,
    player: Player(
      id: 'player-22',
      displayName: 'Kalungi Carey Gingo',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 23,
    player: Player(
      id: 'demo-player-1',
      displayName: 'Tugume Keith',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
  RankingEntry(
    position: 24,
    player: Player(
      id: 'player-24',
      displayName: 'Kutesakwe Andrew',
      lastActivityAt: DateTime(2026, 10, 23),
    ),
  ),
];
