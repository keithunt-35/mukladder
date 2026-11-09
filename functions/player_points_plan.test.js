const assert = require('node:assert/strict');
const { test } = require('node:test');

const { calculatePlayerPoints } = require('./player_points_plan');

test('adds a positive whole-number award to the existing total', () => {
  assert.equal(calculatePlayerPoints(12, 5), 17);
});

test('rejects invalid current totals and non-positive or fractional awards', () => {
  assert.throws(() => calculatePlayerPoints(-1, 2), TypeError);
  assert.throws(() => calculatePlayerPoints(0, 0), RangeError);
  assert.throws(() => calculatePlayerPoints(0, 1.5), RangeError);
});

test('rejects totals outside the safe integer range', () => {
  assert.throws(
    () => calculatePlayerPoints(Number.MAX_SAFE_INTEGER, 1),
    RangeError,
  );
});
