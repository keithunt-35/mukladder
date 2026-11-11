const test = require('node:test');
const assert = require('node:assert');
const {
  calculateMatchWinner,
  calculateNewRankings,
  FormatException,
} = require('./ranking_engine');

test('calculateMatchWinner correctly determines challenger win', () => {
  assert.strictEqual(calculateMatchWinner('6-4, 6-3'), 'challenger');
  assert.strictEqual(calculateMatchWinner('6-7, 6-4, 6-2'), 'challenger');
});

test('calculateMatchWinner correctly determines challenged win', () => {
  assert.strictEqual(calculateMatchWinner('4-6, 3-6'), 'challenged');
  assert.strictEqual(calculateMatchWinner('6-3, 4-6, 2-6'), 'challenged');
});

test('calculateMatchWinner rejects invalid score formats', () => {
  assert.throws(() => calculateMatchWinner('invalid'), FormatException);
  assert.throws(() => calculateMatchWinner('6-6'), FormatException);
  assert.throws(() => calculateMatchWinner(''), FormatException);
});

test('Normal challenge challenger win moves challenger up to challenged position', () => {
  const currentPositions = {
    p1: 1,
    p2: 2,
    p3: 3,
    p4: 4,
    p5: 5,
  };
  const newPositions = calculateNewRankings({
    currentPositions,
    challengerId: 'p5',
    challengedId: 'p2',
    challengeType: 'normal',
    winner: 'challenger',
  });
  assert.deepStrictEqual(newPositions, {
    p1: 1,
    p5: 2,
    p2: 3,
    p3: 4,
    p4: 5,
  });
});

test('Normal challenge challenger loss keeps positions unchanged', () => {
  const currentPositions = {
    p1: 1,
    p2: 2,
    p3: 3,
  };
  const newPositions = calculateNewRankings({
    currentPositions,
    challengerId: 'p3',
    challengedId: 'p1',
    challengeType: 'normal',
    winner: 'challenged',
  });
  assert.deepStrictEqual(newPositions, {
    p1: 1,
    p2: 2,
    p3: 3,
  });
});

test('G.O.D. challenge challenger win swaps positions', () => {
  const currentPositions = {
    p1: 1,
    p2: 2,
    p3: 3,
    p10: 10,
  };
  const newPositions = calculateNewRankings({
    currentPositions,
    challengerId: 'p10',
    challengedId: 'p2',
    challengeType: 'god',
    winner: 'challenger',
  });
  assert.strictEqual(newPositions.p10, 2);
  assert.strictEqual(newPositions.p2, 10);
  assert.strictEqual(newPositions.p1, 1);
  assert.strictEqual(newPositions.p3, 3);
});

test('G.O.D. challenge challenger loss drops challenger to bottom', () => {
  const currentPositions = {
    p1: 1,
    p2: 2,
    p3: 3,
    p4: 4,
  };
  const newPositions = calculateNewRankings({
    currentPositions,
    challengerId: 'p2',
    challengedId: 'p1',
    challengeType: 'god',
    winner: 'challenged',
  });
  assert.deepStrictEqual(newPositions, {
    p1: 1,
    p3: 2,
    p4: 3,
    p2: 4,
  });
});
