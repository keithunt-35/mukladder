const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

const {
  calculatePositionsAfterInsertion,
} = require('./initial_ladder_position_plan');
const { calculatePlayerPoints } = require('./player_points_plan');
const {
  isDuplicatePaymentReport,
  normalizeMtnMomoReference,
} = require('./membership_flow');

initializeApp();
const firestore = getFirestore();

function addAdminNotifications(transaction, adminSnapshot, notification) {
  if (adminSnapshot.empty) {
    throw new HttpsError(
      'failed-precondition',
      'No Ladder Admin account is configured to receive membership requests.',
    );
  }
  for (const adminDocument of adminSnapshot.docs) {
    const notificationReference = firestore
      .collection('notifications')
      .doc();
    transaction.create(notificationReference, {
      recipientId: adminDocument.id,
      ...notification,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
}

exports.approvePlayerRegistration = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in as an Admin to continue.');
  }

  const { userId, initialPosition, paymentVerified } = request.data ?? {};
  if (
    typeof userId !== 'string' ||
    userId.length === 0 ||
    !Number.isInteger(initialPosition) ||
    paymentVerified !== true
  ) {
    throw new HttpsError(
      'invalid-argument',
      'A player ID, integer initial position, and Admin payment confirmation are required.',
    );
  }

  const adminReference = firestore.collection('users').doc(request.auth.uid);
  const userReference = firestore.collection('users').doc(userId);
  const playerReference = firestore.collection('players').doc(userId);
  const rankingsReference = firestore.collection('rankings');
  const ladderStateReference = firestore
    .collection('system')
    .doc('ladderState');
  const auditReference = firestore.collection('auditEvents').doc();
  let assignedPosition;

  await firestore.runTransaction(async (transaction) => {
    const [
      adminSnapshot,
      userSnapshot,
      playerSnapshot,
      ladderStateSnapshot,
      rankingsSnapshot,
    ] = await Promise.all([
      transaction.get(adminReference),
      transaction.get(userReference),
      transaction.get(playerReference),
      transaction.get(ladderStateReference),
      transaction.get(rankingsReference),
    ]);

    if (adminSnapshot.data()?.role !== 'admin') {
      throw new HttpsError(
        'permission-denied',
        'Only the Ladder Admin can approve registrations.',
      );
    }

    const userData = userSnapshot.data();
    const playerData = playerSnapshot.data();
    if (
      !userSnapshot.exists ||
      !playerSnapshot.exists ||
      userData?.role !== 'player' ||
      userData?.registrationStatus !== 'pending' ||
      userData?.joinRequestStatus !== 'paymentReported' ||
      userData?.paymentStatus !== 'reported' ||
      typeof userData?.paymentReference !== 'string' ||
      playerData?.userId !== userId ||
      playerData?.registrationStatus !== 'pending' ||
      playerData?.joinRequestStatus !== 'paymentReported' ||
      playerData?.paymentStatus !== 'reported' ||
      playerData?.active !== false
    ) {
      throw new HttpsError(
        'failed-precondition',
        'This player is not awaiting registration approval.',
      );
    }

    if (
      rankingsSnapshot.docs.some((document) => {
        const data = document.data();
        return (
          document.id === userId ||
          data.playerId === userId ||
          data.player?.id === userId
        );
      })
    ) {
      throw new HttpsError(
        'already-exists',
        'This player already has a ladder position.',
      );
    }

    const currentPositions = {};
    for (const document of rankingsSnapshot.docs) {
      const position = document.data().position;
      if (!Number.isInteger(position)) {
        throw new HttpsError(
          'failed-precondition',
          'The existing ladder has invalid positions. Reconcile it before '
            + 'approving a player.',
        );
      }
      currentPositions[document.id] = position;
    }

    let plannedPositions;
    try {
      plannedPositions = calculatePositionsAfterInsertion(
        currentPositions,
        userId,
        initialPosition,
      );
    } catch (error) {
      const code =
        error instanceof RangeError ? 'invalid-argument' : 'failed-precondition';
      throw new HttpsError(code, error.message);
    }

    const ladderStateData = ladderStateSnapshot.data();
    const revision = ladderStateSnapshot.exists
      ? ladderStateData?.revision
      : 0;
    if (!Number.isInteger(revision) || revision < 0) {
      throw new HttpsError(
        'failed-precondition',
        'Ladder state is invalid. Ask an administrator to reconcile it.',
      );
    }

    for (const document of rankingsSnapshot.docs) {
      const nextPosition = plannedPositions[document.id];
      if (nextPosition !== document.data().position) {
        transaction.update(document.ref, { position: nextPosition });
      }
    }

    assignedPosition = plannedPositions[userId];
    transaction.create(rankingsReference.doc(userId), {
      playerId: userId,
      position: assignedPosition,
      effectiveAt: FieldValue.serverTimestamp(),
      sourceResultId: null,
      version: 1,
    });
    transaction.update(userReference, {
      registrationStatus: 'approved',
      joinRequestStatus: 'approved',
      paymentStatus: 'paid',
      approvedBy: request.auth.uid,
      approvedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(playerReference, {
      registrationStatus: 'approved',
      joinRequestStatus: 'approved',
      paymentStatus: 'paid',
      active: true,
      approvedBy: request.auth.uid,
      approvedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(auditReference, {
      actorId: request.auth.uid,
      actorRole: 'admin',
      eventType: 'registrationApproved',
      entityType: 'player',
      entityId: userId,
      before: {
        registrationStatus: 'pending',
        joinRequestStatus: 'paymentReported',
        paymentStatus: 'reported',
        paymentReference: userData.paymentReference,
      },
      after: {
        registrationStatus: 'approved',
        joinRequestStatus: 'approved',
        paymentStatus: 'paid',
        initialPosition: assignedPosition,
        membershipFeeUgx: 40000,
        shiftedPlayerIds: rankingsSnapshot.docs
          .filter(
            (document) =>
              plannedPositions[document.id] !== document.data().position,
          )
          .map((document) => document.id),
      },
      reason: 'Admin verified the membership payment.',
      createdAt: FieldValue.serverTimestamp(),
    });
    const playerNotificationReference = firestore
      .collection('notifications')
      .doc();
    transaction.create(playerNotificationReference, {
      recipientId: userId,
      title: 'Ladder membership approved',
      body: `Your UGX 40,000 payment is verified. You have joined the ladder at position ${assignedPosition}.`,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.set(ladderStateReference, {
      revision: revision + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { approved: true, initialPosition: assignedPosition };
});

exports.requestToJoinLadder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in to request ladder membership.');
  }

  const userId = request.auth.uid;
  const userReference = firestore.collection('users').doc(userId);
  const playerReference = firestore.collection('players').doc(userId);
  const adminQuery = firestore.collection('users').where('role', '==', 'admin');
  const auditReference = firestore.collection('auditEvents').doc();

  return firestore.runTransaction(async (transaction) => {
    const [userSnapshot, playerSnapshot, adminSnapshot] = await Promise.all([
      transaction.get(userReference),
      transaction.get(playerReference),
      transaction.get(adminQuery),
    ]);
    const userData = userSnapshot.data();
    const playerData = playerSnapshot.data();
    if (
      !userSnapshot.exists ||
      !playerSnapshot.exists ||
      userData?.role !== 'player' ||
      playerData?.userId !== userId ||
      playerData?.registrationStatus === 'approved' ||
      playerData?.active === true
    ) {
      throw new HttpsError(
        'failed-precondition',
        'A valid player profile is required to request membership.',
      );
    }

    if (userData.registrationStatus === 'approved') {
      throw new HttpsError(
        'failed-precondition',
        'This account has already joined the ladder.',
      );
    }
    if (
      userData.joinRequestStatus === 'requested' ||
      userData.joinRequestStatus === 'paymentReported'
    ) {
      return { requested: true, duplicate: true };
    }
    if (
      userData.registrationStatus !== 'notRequested' &&
      userData.registrationStatus !== 'pending'
    ) {
      throw new HttpsError(
        'failed-precondition',
        'This account cannot request ladder membership right now.',
      );
    }

    transaction.update(userReference, {
      registrationStatus: 'pending',
      joinRequestStatus: 'requested',
      paymentStatus: 'pending',
      joinRequestedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(playerReference, {
      registrationStatus: 'pending',
      joinRequestStatus: 'requested',
      paymentStatus: 'pending',
      joinRequestedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    addAdminNotifications(transaction, adminSnapshot, {
      type: 'ladderJoinRequested',
      title: 'New ladder membership request',
      body: `${userData.displayName} (${userData.email}) wants to join the ladder. Review this player in the Admin workspace to approve their request. Membership fee: UGX 40,000.`,
      entityId: userId,
    });
    transaction.create(auditReference, {
      actorId: userId,
      actorRole: 'player',
      eventType: 'ladderJoinRequested',
      entityType: 'player',
      entityId: userId,
      before: {
        registrationStatus: userData.registrationStatus,
        joinRequestStatus: userData.joinRequestStatus ?? 'notRequested',
      },
      after: {
        registrationStatus: 'pending',
        joinRequestStatus: 'requested',
        paymentStatus: 'pending',
      },
      reason: 'Player requested to join the ladder.',
      createdAt: FieldValue.serverTimestamp(),
    });
    return { requested: true, duplicate: false };
  });
});

exports.reportLadderPayment = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in to report your payment.');
  }

  let transactionReference;
  try {
    transactionReference = normalizeMtnMomoReference(
      request.data?.transactionReference,
    );
  } catch (error) {
    throw new HttpsError(
      'invalid-argument',
      error.message,
    );
  }

  const userId = request.auth.uid;
  const userReference = firestore.collection('users').doc(userId);
  const playerReference = firestore.collection('players').doc(userId);
  const adminQuery = firestore.collection('users').where('role', '==', 'admin');
  const auditReference = firestore.collection('auditEvents').doc();

  return firestore.runTransaction(async (transaction) => {
    const [userSnapshot, playerSnapshot, adminSnapshot] = await Promise.all([
      transaction.get(userReference),
      transaction.get(playerReference),
      transaction.get(adminQuery),
    ]);
    const userData = userSnapshot.data();
    const joinRequestPending =
      userData?.joinRequestStatus === 'requested' ||
      (userData?.joinRequestStatus == null &&
        userData?.registrationStatus === 'pending' &&
        userData?.paymentStatus === 'pending');
    if (
      !userSnapshot.exists ||
      !playerSnapshot.exists ||
      userData?.role !== 'player' ||
      userData?.registrationStatus !== 'pending' ||
      !joinRequestPending ||
      playerSnapshot.data()?.userId !== userId ||
      playerSnapshot.data()?.registrationStatus !== 'pending' ||
      playerSnapshot.data()?.paymentStatus !== 'pending'
    ) {
      if (isDuplicatePaymentReport(
        userData?.joinRequestStatus,
        userData?.paymentReference,
        transactionReference,
      )) {
        return { reported: true, duplicate: true };
      }
      throw new HttpsError(
        'failed-precondition',
        'Request to join the ladder before reporting payment.',
      );
    }

    transaction.update(userReference, {
      joinRequestStatus: 'paymentReported',
      paymentStatus: 'reported',
      paymentReference: transactionReference,
      paymentReportedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(playerReference, {
      joinRequestStatus: 'paymentReported',
      paymentStatus: 'reported',
      paymentReference: transactionReference,
      paymentReportedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    addAdminNotifications(transaction, adminSnapshot, {
      type: 'ladderPaymentReported',
      title: 'Player reported a membership payment',
      body: `${userData.displayName} (${userData.email}) reports paying UGX 40,000. MTN MoMo reference: ${transactionReference}. Verify it before approval.`,
      entityId: userId,
    });
    transaction.create(auditReference, {
      actorId: userId,
      actorRole: 'player',
      eventType: 'ladderPaymentReported',
      entityType: 'player',
      entityId: userId,
      before: {
        joinRequestStatus: 'requested',
        paymentStatus: 'pending',
      },
      after: {
        joinRequestStatus: 'paymentReported',
        paymentStatus: 'reported',
        paymentReference: transactionReference,
      },
      reason: 'Player submitted an external MTN MoMo payment reference; Admin verification is required.',
      createdAt: FieldValue.serverTimestamp(),
    });
    return { reported: true, duplicate: false };
  });
});

exports.addPlayerPoints = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in as an Admin to continue.');
  }

  const { requestId, playerId, points, reason } = request.data ?? {};
  if (
    typeof requestId !== 'string' ||
    !/^[A-Za-z0-9_-]{20,128}$/.test(requestId) ||
    typeof playerId !== 'string' ||
    playerId.length === 0 ||
    !Number.isSafeInteger(points) ||
    points <= 0 ||
    typeof reason !== 'string' ||
    reason.trim().length === 0 ||
    reason.trim().length > 300
  ) {
    throw new HttpsError(
      'invalid-argument',
      'A player, positive whole-number points amount, reason (up to 300 '
        + 'characters), and valid request ID are required.',
    );
  }

  const adminReference = firestore.collection('users').doc(request.auth.uid);
  const playerReference = firestore.collection('players').doc(playerId);
  const pointsReference = firestore.collection('playerPoints').doc(playerId);
  const eventReference = firestore
    .collection('playerPointEvents')
    .doc(requestId);
  const auditReference = firestore.collection('auditEvents').doc();

  return firestore.runTransaction(async (transaction) => {
    const [
      adminSnapshot,
      playerSnapshot,
      pointsSnapshot,
      eventSnapshot,
    ] = await Promise.all([
      transaction.get(adminReference),
      transaction.get(playerReference),
      transaction.get(pointsReference),
      transaction.get(eventReference),
    ]);

    if (adminSnapshot.data()?.role !== 'admin') {
      throw new HttpsError(
        'permission-denied',
        'Only the Ladder Admin can award player points.',
      );
    }

    if (eventSnapshot.exists) {
      const event = eventSnapshot.data();
      if (
        event?.actorId !== request.auth.uid ||
        event?.playerId !== playerId ||
        event?.pointsAdded !== points ||
        event?.reason !== reason.trim()
      ) {
        throw new HttpsError(
          'already-exists',
          'This points request ID was already used for another adjustment.',
        );
      }
      return { totalPoints: event.totalPointsAfter, duplicate: true };
    }

    const playerData = playerSnapshot.data();
    if (
      !playerSnapshot.exists ||
      playerData?.registrationStatus === 'pending' ||
      playerData?.active === false
    ) {
      throw new HttpsError(
        'failed-precondition',
        'Points can only be added to an active, approved player.',
      );
    }

    const currentTotal = pointsSnapshot.exists
      ? pointsSnapshot.data()?.totalPoints
      : 0;
    let totalPoints;
    try {
      totalPoints = calculatePlayerPoints(currentTotal, points);
    } catch (error) {
      throw new HttpsError('failed-precondition', error.message);
    }

    const now = FieldValue.serverTimestamp();
    transaction.set(
      pointsReference,
      {
        playerId,
        totalPoints,
        updatedBy: request.auth.uid,
        updatedAt: now,
        ...(pointsSnapshot.exists
          ? {}
          : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
    transaction.create(eventReference, {
      actorId: request.auth.uid,
      playerId,
      pointsAdded: points,
      totalPointsBefore: currentTotal,
      totalPointsAfter: totalPoints,
      reason: reason.trim(),
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.create(auditReference, {
      actorId: request.auth.uid,
      actorRole: 'admin',
      eventType: 'playerPointsAdded',
      entityType: 'player',
      entityId: playerId,
      before: { totalPoints: currentTotal },
      after: { totalPoints, pointsAdded: points },
      reason: reason.trim(),
      createdAt: FieldValue.serverTimestamp(),
    });
    return { totalPoints, duplicate: false };
  });
});
