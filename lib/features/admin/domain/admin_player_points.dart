class AdminPlayerPoints {
  const AdminPlayerPoints({
    required this.playerId,
    required this.displayName,
    required this.totalPoints,
    required this.active,
    required this.registrationStatus,
  });

  final String playerId;
  final String displayName;
  final int totalPoints;
  final bool active;
  final String? registrationStatus;

  bool get canReceivePoints => active && registrationStatus != 'pending';
}
