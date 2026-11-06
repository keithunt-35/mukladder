const assert = require('node:assert/strict');
const { test } = require('node:test');

const {
  isDuplicatePaymentReport,
  normalizeMtnMomoReference,
} = require('./membership_flow');

test('normalizes a valid MTN MoMo transaction reference', () => {
  assert.equal(normalizeMtnMomoReference('  abc-1234  '), 'abc-1234');
});

test('rejects missing and malformed payment references', () => {
  assert.throws(() => normalizeMtnMomoReference(null), TypeError);
  assert.throws(() => normalizeMtnMomoReference('abc'), RangeError);
  assert.throws(() => normalizeMtnMomoReference('abcd/1234'), RangeError);
});

test('only treats the same reported reference as an idempotent retry', () => {
  assert.equal(isDuplicatePaymentReport('paymentReported', 'ref1', 'ref1'), true);
  assert.equal(isDuplicatePaymentReport('requested', 'ref1', 'ref1'), false);
  assert.equal(isDuplicatePaymentReport('paymentReported', 'ref1', 'ref2'), false);
});
