import '../domain/ranking_entry.dart';
import 'ranking_repository.dart';

class InMemoryRankingRepository implements RankingRepository {
  InMemoryRankingRepository({
    Iterable<RankingEntry> entries = const [],
    this.shouldFail = false,
  }) : _entries = List.unmodifiable(entries);

  final List<RankingEntry> _entries;
  final bool shouldFail;

  @override
  Future<List<RankingEntry>> getRanking() async {
    if (shouldFail) {
      throw StateError('Demo ranking data is unavailable.');
    }

    return _entries;
  }
}
