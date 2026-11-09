function toPublicLadder(rankingDocuments, playersById) {
  return rankingDocuments.map((document) => {
    const data = document.data();
    const embeddedPlayer = data.player ?? {};
    const playerId =
      data.playerId ?? embeddedPlayer.id ?? document.id;
    const playerData = playersById.get(playerId) ?? {};
    const displayName =
      playerData.displayName ?? embeddedPlayer.displayName;

    if (
      typeof playerId !== 'string' ||
      typeof displayName !== 'string' ||
      !Number.isInteger(data.position) ||
      data.position < 1
    ) {
      throw new Error(
        `Ranking document ${document.id} is missing public player data.`,
      );
    }

    const lastActivityAt = playerData.lastActivityAt;
    const activityDate =
      lastActivityAt && typeof lastActivityAt.toDate === 'function'
        ? lastActivityAt.toDate()
        : typeof lastActivityAt === 'string'
        ? new Date(lastActivityAt)
        : null;
    return {
      playerId,
      position: data.position,
      displayName,
      photoUrl: playerData.photoUrl ?? embeddedPlayer.photoUrl ?? null,
      lastActivityAt:
        activityDate && !Number.isNaN(activityDate.getTime())
          ? activityDate.toISOString()
          : null,
      active:
        playerData.active ?? embeddedPlayer.active ?? true,
    };
  });
}

module.exports = { toPublicLadder };
