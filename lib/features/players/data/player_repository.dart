import '../domain/player.dart';

abstract interface class PlayerRepository {
  Future<List<Player>> getPlayers();
}
