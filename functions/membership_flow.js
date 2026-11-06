function normalizeMtnMomoReference(value) {
  if (typeof value !== 'string') {
    throw new TypeError('The MTN MoMo reference must be text.');
  }
  const reference = value.trim();
  if (!/^[A-Za-z0-9-]{4,80}$/.test(reference)) {
    throw new RangeError(
      'Enter a valid MTN MoMo transaction reference (4 to 80 letters or numbers).',
    );
  }
  return reference;
}

function isDuplicatePaymentReport(status, storedReference, submittedReference) {
  return (
    status === 'paymentReported' &&
    storedReference === submittedReference
  );
}

module.exports = {
  isDuplicatePaymentReport,
  normalizeMtnMomoReference,
};
