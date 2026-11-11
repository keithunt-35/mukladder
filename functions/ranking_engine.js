function calculateMatchWinner(score) {
  if (typeof score !== 'string' || score.trim().length === 0) {
    throw new FormatException('Score must be a non-empty string.');
  }
  let challengerSets = 0;
  let challengedSets = 0;
  const sets = score.split(',');
  for (const setScore of sets) {
    const parts = setScore.trim().split('-');
    if (parts.length !== 2) {
      throw new FormatException('Invalid set score format.');
    }
    const challengerGames = parseInt(parts[0], 10);
    const challengedGames = parseInt(parts[1], 10);
    if (
      isNaN(challengerGames) ||
      isNaN(challengedGames) ||
      challengerGames < 0 ||
      challengedGames < 0 ||
      challengerGames === challengedGames
    ) {
      throw new FormatException('Invalid games count in score.');
    }
    if (challengerGames > challengedGames) {
      challengerSets++;
    } else {
      challengedSets++;
    }
  }
  if (challengerSets === challengedSets) {
    throw new FormatException('Match score must have a clear winner.');
  }
  return challengerSets > challengedSets ? 'challenger' : 'challenged';
}

function calculateNewRankings({
  currentPositions,
  challengerId,
  challengedId,
  challengeType,
  winner,
}) {
  if (!currentPositions || typeof currentPositions !== 'object') {
    throw new Error('Current positions object is required.');
  }
  const playerIds = Object.keys(currentPositions);
  if (!playerIds.includes(challengerId) || !playerIds.includes(challengedId)) {
    throw new Error('Both participants must exist on the ladder.');
  }

  // Sort players by position
  const sorted = playerIds
    .map((id) => ({ id, pos: currentPositions[id] }))
    .sort((a, b) => a.pos - b.pos);

  const challengerIndex = sorted.findIndex((p) => p.id === challengerId);
  const challengedIndex = sorted.findIndex((p) => p.id === challengedId);

  if (winner === 'challenger') {
    if (challengeType === 'god') {
      // G.O.D. win: Swap positions
      const tempPos = sorted[challengerIndex].pos;
      sorted[challengerIndex].pos = sorted[challengedIndex].pos;
      sorted[challengedIndex].pos = tempPos;
    } else if (challengerIndex > challengedIndex) {
      // Normal win: Challenger moves up to challenged position
      const [challenger] = sorted.splice(challengerIndex, 1);
      sorted.splice(challengedIndex, 0, challenger);
      // Reassign sequential positions after move
      sorted.forEach((player, index) => {
        player.pos = index + 1;
      });
    }
  } else if (winner === 'challenged') {
    if (challengeType === 'god') {
      // G.O.D. loss: Challenger drops to the bottom of the ladder
      const [challenger] = sorted.splice(challengerIndex, 1);
      sorted.push(challenger);
      // Reassign sequential positions after move
      sorted.forEach((player, index) => {
        player.pos = index + 1;
      });
    }
    // Normal loss: No position changes
  }

  const result = {};
  sorted.forEach((player, index) => {
    result[player.id] = player.pos;
  });
  return result;
}

class FormatException extends Error {
  constructor(message) {
    super(message);
    this.name = 'FormatException';
  }
}

module.exports = {
  calculateMatchWinner,
  calculateNewRankings,
  FormatException,
};
