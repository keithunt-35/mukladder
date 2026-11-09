import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../data/in_memory_ranking_repository.dart';
import '../../players/domain/player.dart';
import '../data/firestore_ranking_repository.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return InMemoryRankingRepository(entries: demoRankingEntries);
  }
  return FirestoreRankingRepository();
});

final rankingProvider = FutureProvider<List<RankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).getRanking();
});

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
];
