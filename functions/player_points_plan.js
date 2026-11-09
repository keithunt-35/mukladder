function calculatePlayerPoints(currentTotal, pointsToAdd) {
  if (!Number.isSafeInteger(currentTotal) || currentTotal < 0) {
    throw new TypeError('The current points total must be a non-negative integer.');
  }
  if (!Number.isSafeInteger(pointsToAdd) || pointsToAdd <= 0) {
    throw new RangeError('Points to add must be a positive integer.');
  }

  const nextTotal = currentTotal + pointsToAdd;
  if (!Number.isSafeInteger(nextTotal)) {
    throw new RangeError('The resulting points total is too large.');
  }
  return nextTotal;
}

module.exports = { calculatePlayerPoints };
