const assert = require('node:assert/strict');
const { test } = require('node:test');

const {
  calculatePositionsAfterInsertion,
} = require('./initial_ladder_position_plan');

test('inserts a player and shifts later positions', () => {
  assert.deepEqual(
    calculatePositionsAfterInsertion(
      { playerA: 1, playerB: 2, playerC: 3 },
      'newPlayer',
      2,
    ),
    { playerA: 1, playerB: 3, playerC: 4, newPlayer: 2 },
  );
});

test('rejects gaps and duplicate positions in the current ladder', () => {
  assert.throws(
    () =>
      calculatePositionsAfterInsertion(
        { playerA: 1, playerB: 3 },
        'newPlayer',
        2,
      ),
    /must be consecutive/,
  );
});

test('rejects assigning a second position to an existing player', () => {
  assert.throws(
    () =>
      calculatePositionsAfterInsertion(
        { playerA: 1 },
        'playerA',
        2,
      ),
    /already has a ladder position/,
  );
});

test('rejects positions outside the current ladder bounds', () => {
  assert.throws(
    () =>
      calculatePositionsAfterInsertion(
        { playerA: 1 },
        'newPlayer',
        3,
      ),
    RangeError,
  );
});
