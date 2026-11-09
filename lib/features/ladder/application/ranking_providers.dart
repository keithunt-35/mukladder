import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_ranking_repository.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return FirestoreRankingRepository();
});

final rankingProvider = StreamProvider<List<RankingEntry>>((ref) {
  // All authenticated users — including those with pending membership — use
  // the same Firestore ranking stream.  The public ladder callable
  // (getPublicLadder) is kept for future use but is not required for the
  // in-app experience; Firestore Security Rules control what data each role
  // can read at the database level.
  return ref.watch(rankingRepositoryProvider).watchRanking();
});
