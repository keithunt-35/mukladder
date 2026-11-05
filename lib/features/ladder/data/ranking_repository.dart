import '../domain/ranking_entry.dart';

abstract interface class RankingRepository {
  Future<List<RankingEntry>> getRanking();

  Stream<List<RankingEntry>> watchRanking();
}
