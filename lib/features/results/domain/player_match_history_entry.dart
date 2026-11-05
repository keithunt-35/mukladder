import '../../challenges/domain/challenge.dart';
import 'match_result.dart';

class PlayerMatchHistoryEntry {
  const PlayerMatchHistoryEntry({
    required this.challengeId,
    required this.opponentName,
    required this.score,
    required this.status,
    required this.challengeType,
    required this.playedAt,
  });

  final String challengeId;
  final String opponentName;
  final String score;
  final ResultStatus status;
  final ChallengeType challengeType;
  final DateTime playedAt;

  String get statusLabel => switch (status) {
    ResultStatus.submitted => 'Awaiting confirmation',
    ResultStatus.confirmed => 'Confirmed',
    ResultStatus.disputed => 'Disputed',
  };

  String get challengeTypeLabel => switch (challengeType) {
    ChallengeType.normal => 'Normal',
    ChallengeType.god => 'G.O.D.',
  };
}
