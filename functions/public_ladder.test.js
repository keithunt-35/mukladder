const assert = require('node:assert/strict');
const { test } = require('node:test');

const { toPublicLadder } = require('./public_ladder');

test('returns standings with only public player fields', () => {
  const lastActivityAt = {
    toDate: () => new Date('2026-11-08T10:00:00.000Z'),
  };
  const entries = toPublicLadder(
    [
      {
        id: 'player-1',
        data: () => ({ playerId: 'player-1', position: 1 }),
      },
    ],
    new Map([
      [
        'player-1',
        {
          displayName: 'Player One',
          photoUrl: 'https://example.test/player.jpg',
          lastActivityAt,
          active: true,
          email: 'private@example.test',
          paymentReference: 'PRIVATE-123',
          paymentStatus: 'reported',
        },
      ],
    ]),
  );

  assert.deepEqual(entries, [
    {
      playerId: 'player-1',
      position: 1,
      displayName: 'Player One',
      photoUrl: 'https://example.test/player.jpg',
      lastActivityAt: '2026-11-08T10:00:00.000Z',
      active: true,
    },
  ]);
});

test('uses public ranking fields when a player profile is unavailable', () => {
  const entries = toPublicLadder(
    [
      {
        id: 'player-2',
        data: () => ({
          playerId: 'player-2',
          position: 2,
          player: {
            id: 'player-2',
            displayName: 'Player Two',
            photoUrl: null,
            active: true,
          },
        }),
      },
    ],
    new Map(),
  );

  assert.equal(entries[0].displayName, 'Player Two');
  assert.equal(entries[0].photoUrl, null);
});

test('rejects ranking data without the public player name or position', () => {
  assert.throws(
    () =>
      toPublicLadder(
        [{ id: 'player-3', data: () => ({ playerId: 'player-3' }) }],
        new Map(),
      ),
    /missing public player data/,
  );
});
