const test = require('node:test');
const assert = require('node:assert');
const { calculateInactivityDrops } = require('./inactivity_plan');

test('no drops when every player challenged within seven days', () => {
  const asOf = new Date('2026-11-11T12:00:00Z');
  const result = calculateInactivityDrops({
    currentPositions: { a: 1, b: 2, c: 3 },
    lastChallengeAtByPlayerId: {
      a: new Date('2026-11-10T12:00:00Z'),
      b: new Date('2026-11-09T12:00:00Z'),
      c: new Date('2026-11-05T12:00:00Z'),
    },
    asOf,
  });
  assert.deepStrictEqual(result.positions, { a: 1, b: 2, c: 3 });
  assert.deepStrictEqual(result.changedPlayerIds, {});
});

test('one full inactive week drops a player one position', () => {
  const asOf = new Date('2026-11-11T12:00:00Z');
  const result = calculateInactivityDrops({
    currentPositions: { a: 1, b: 2, c: 3 },
    lastChallengeAtByPlayerId: {
      a: new Date('2026-11-01T12:00:00Z'), // 10 days => 1 drop
      b: new Date('2026-11-10T12:00:00Z'),
      c: new Date('2026-11-10T12:00:00Z'),
    },
    asOf,
  });
  assert.deepStrictEqual(result.positions, { b: 1, a: 2, c: 3 });
  assert.deepStrictEqual(result.changedPlayerIds.a, {
    from: 1,
    to: 2,
    drops: 1,
  });
});

test('two inactive weeks can drop a player multiple positions', () => {
  const asOf = new Date('2026-11-11T12:00:00Z');
  const result = calculateInactivityDrops({
    currentPositions: { a: 1, b: 2, c: 3, d: 4 },
    lastChallengeAtByPlayerId: {
      a: new Date('2026-10-20T12:00:00Z'), // 22 days => 3 drops
      b: new Date('2026-11-10T12:00:00Z'),
      c: new Date('2026-11-10T12:00:00Z'),
      d: new Date('2026-11-10T12:00:00Z'),
    },
    asOf,
  });
  assert.deepStrictEqual(result.positions, { b: 1, c: 2, d: 3, a: 4 });
  assert.strictEqual(result.changedPlayerIds.a.drops, 3);
});

test('missing last-challenge timestamps are treated as zero drops', () => {
  const asOf = new Date('2026-11-11T12:00:00Z');
  const result = calculateInactivityDrops({
    currentPositions: { a: 1, b: 2 },
    lastChallengeAtByPlayerId: {
      b: new Date('2026-11-10T12:00:00Z'),
    },
    asOf,
  });
  assert.deepStrictEqual(result.positions, { a: 1, b: 2 });
  assert.deepStrictEqual(result.changedPlayerIds, {});
});

test('rejects gapped ladder positions', () => {
  assert.throws(
    () =>
      calculateInactivityDrops({
        currentPositions: { a: 1, b: 3 },
        lastChallengeAtByPlayerId: {},
        asOf: new Date('2026-11-11T12:00:00Z'),
      }),
    /consecutive/,
  );
});
