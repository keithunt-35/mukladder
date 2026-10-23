import '../domain/player.dart';
import 'player_repository.dart';

class InMemoryPlayerRepository implements PlayerRepository {
  InMemoryPlayerRepository({
    Iterable<Player> players = const [],
    this.shouldFail = false,
  }) : _players = List.unmodifiable(players);

  final List<Player> _players;
  final bool shouldFail;

  @override
  Future<List<Player>> getPlayers() async {
    if (shouldFail) {
      throw StateError('Demo player data is unavailable.');
    }

    return _players;
  }
}
