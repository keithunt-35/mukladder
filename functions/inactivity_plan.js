/**
 * Provisional Rule 10 planner.
 *
 * Concept paper / MUK Ladder Rules, 2025 summary: a player drops one position
 * for every full seven days without a challenge. Exact 2026 applicability must
 * still be confirmed with the Ladder Admin before treating this as final law.
 */

function daysBetween(earlier, later) {
  const start = Date.UTC(
    earlier.getUTCFullYear(),
    earlier.getUTCMonth(),
    earlier.getUTCDate(),
  );
  const end = Date.UTC(
    later.getUTCFullYear(),
    later.getUTCMonth(),
    later.getUTCDate(),
  );
  return Math.floor((end - start) / (24 * 60 * 60 * 1000));
}

function calculateInactivityDrops({
  currentPositions,
  lastChallengeAtByPlayerId,
  asOf,
  inactiveDaysPerDrop = 7,
}) {
  if (!currentPositions || typeof currentPositions !== 'object') {
    throw new Error('Current positions object is required.');
  }
  if (!(asOf instanceof Date) || Number.isNaN(asOf.getTime())) {
    throw new Error('A valid asOf date is required.');
  }
  if (!Number.isInteger(inactiveDaysPerDrop) || inactiveDaysPerDrop < 1) {
    throw new Error('inactiveDaysPerDrop must be a positive integer.');
  }

  const ordered = Object.keys(currentPositions)
    .map((id) => ({ id, pos: currentPositions[id] }))
    .sort((a, b) => a.pos - b.pos);

  for (let index = 0; index < ordered.length; index += 1) {
    if (!Number.isInteger(ordered[index].pos) || ordered[index].pos !== index + 1) {
      throw new Error(
        'Ranking positions must be consecutive integers starting at 1.',
      );
    }
  }

  const dropCounts = {};
  for (const player of ordered) {
    const lastChallengeAt = lastChallengeAtByPlayerId?.[player.id];
    if (!(lastChallengeAt instanceof Date) || Number.isNaN(lastChallengeAt.getTime())) {
      dropCounts[player.id] = 0;
      continue;
    }
    const inactiveDays = daysBetween(lastChallengeAt, asOf);
    dropCounts[player.id] = Math.max(
      0,
      Math.floor(inactiveDays / inactiveDaysPerDrop),
    );
  }

  // Process from bottom to top so simultaneous drops preserve relative order
  // among inactive players while letting active players bubble above them.
  const working = ordered.map((player) => ({ ...player }));
  for (let index = working.length - 1; index >= 0; index -= 1) {
    const drops = dropCounts[working[index].id];
    if (!drops) {
      continue;
    }
    const player = working.splice(index, 1)[0];
    const targetIndex = Math.min(working.length, index + drops);
    working.splice(targetIndex, 0, player);
  }

  const positions = {};
  const changedPlayerIds = {};
  working.forEach((player, index) => {
    const nextPos = index + 1;
    positions[player.id] = nextPos;
    if (nextPos !== currentPositions[player.id]) {
      changedPlayerIds[player.id] = {
        from: currentPositions[player.id],
        to: nextPos,
        drops: dropCounts[player.id],
      };
    }
  });

  return { positions, changedPlayerIds, dropCounts };
}

module.exports = {
  calculateInactivityDrops,
  daysBetween,
};
