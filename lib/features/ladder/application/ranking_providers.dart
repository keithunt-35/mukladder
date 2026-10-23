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

final demoRankingEntries = <RankingEntry>[
  RankingEntry(
    position: 1,
    player: Player(
      id: 'player-1',
      displayName: 'Demo Player',
      lastActivityAt: DateTime(2026, 10, 23),
      paymentStatus: PaymentStatus.paid,
    ),
  ),
  RankingEntry(
    position: 2,
    player: Player(
      id: 'player-2',
      displayName: 'Joel Niwamanya',
      lastActivityAt: DateTime(2026, 10, 22),
      paymentStatus: PaymentStatus.paid,
    ),
  ),
  RankingEntry(
    position: 3,
    player: Player(
      id: 'player-3',
      displayName: 'Joseph Moola',
      lastActivityAt: DateTime(2026, 10, 20),
      paymentStatus: PaymentStatus.pending,
    ),
  ),
];
