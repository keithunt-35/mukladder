import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_ranking_repository.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return FirestoreRankingRepository();
});

final rankingProvider = StreamProvider<List<RankingEntry>>((ref) {
  return ref.watch(rankingRepositoryProvider).watchRanking();
});
