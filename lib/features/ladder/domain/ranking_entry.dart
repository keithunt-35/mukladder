import '../../players/domain/player.dart';

class RankingEntry {
  const RankingEntry({required this.player, required this.position})
    : assert(position > 0);

  final Player player;
  final int position;
}
