function calculatePositionsAfterInsertion(
  currentPositions,
  newPlayerId,
  initialPosition,
) {
  if (Object.hasOwn(currentPositions, newPlayerId)) {
    throw new Error('Player already has a ladder position.');
  }

  const positions = Object.values(currentPositions).sort((a, b) => a - b);
  if (!positions.every((position, index) => position === index + 1)) {
    throw new Error('Current ladder positions must be consecutive.');
  }
  if (
    !Number.isInteger(initialPosition) ||
    initialPosition < 1 ||
    initialPosition > positions.length + 1
  ) {
    throw new RangeError(
      `Choose a position from 1 to ${positions.length + 1}.`,
    );
  }

  return {
    ...Object.fromEntries(
      Object.entries(currentPositions).map(([playerId, position]) => [
        playerId,
        position >= initialPosition ? position + 1 : position,
      ]),
    ),
    [newPlayerId]: initialPosition,
  };
}

module.exports = { calculatePositionsAfterInsertion };
