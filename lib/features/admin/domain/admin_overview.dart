class AdminOverview {
  const AdminOverview({
    required this.totalPlayers,
    required this.activePlayers,
    required this.pendingChallenges,
    required this.unresolvedResults,
    required this.auditEvents,
  });

  final int totalPlayers;
  final int activePlayers;
  final int pendingChallenges;
  final int unresolvedResults;
  final int auditEvents;
}
