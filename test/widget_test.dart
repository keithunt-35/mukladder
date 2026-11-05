import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukladder/app/app.dart';
import 'package:mukladder/app/app_brand.dart';
import 'package:mukladder/features/admin/application/admin_overview_provider.dart';
import 'package:mukladder/features/admin/domain/admin_overview.dart';
import 'package:mukladder/features/auth/application/auth_providers.dart';
import 'package:mukladder/features/auth/domain/app_user.dart';
import 'package:mukladder/features/challenges/application/challenge_providers.dart';
import 'package:mukladder/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:mukladder/features/challenges/domain/challenge.dart';
import 'package:mukladder/features/ladder/application/ranking_providers.dart';
import 'package:mukladder/features/ladder/domain/ranking_entry.dart';
import 'package:mukladder/features/notifications/application/notification_providers.dart';
import 'package:mukladder/features/notifications/data/in_memory_notification_repository.dart';
import 'package:mukladder/features/players/domain/player.dart';
import 'package:mukladder/features/players/presentation/player_avatar.dart';
import 'package:mukladder/features/results/application/result_providers.dart';
import 'package:mukladder/features/results/data/in_memory_result_repository.dart';
import 'package:mukladder/features/results/domain/player_match_history_entry.dart';
import 'package:mukladder/features/results/domain/match_result.dart';

void main() {
  testWidgets('shows the branded live ladder', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('MUKLadder'), findsOneWidget);
    expect(find.text('MAKERERE UNIVERSITY'), findsOneWidget);
    expect(find.text('Tugume Keith'), findsNWidgets(2));
    expect(find.text('Current standings'), findsOneWidget);
    expect(find.text('Opponent'), findsOneWidget);
    expect(find.byType(AppBrandMark), findsNWidgets(2));
  });

  testWidgets('renders ladder changes emitted by Firestore stream', (
    tester,
  ) async {
    final controller = StreamController<List<RankingEntry>>();
    await tester.pumpWidget(_testApp(rankingStream: controller.stream));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.add(_rankingEntries);
    await tester.pumpAndSettle();
    expect(find.text('Opponent'), findsOneWidget);

    final updated = [_rankingEntries[1], _rankingEntries[0]]
        .asMap()
        .entries
        .map(
          (item) =>
              RankingEntry(player: item.value.player, position: item.key + 1),
        )
        .toList();
    controller.add(updated);
    await tester.pumpAndSettle();
    expect(find.text('#1'), findsOneWidget);

    await controller.close();
  });

  testWidgets('shows an empty state when ranking has no entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(rankingStream: Stream.value(const <RankingEntry>[])),
    );
    await tester.pumpAndSettle();

    expect(find.text('No ranking data yet'), findsOneWidget);
  });

  testWidgets('shows ranking errors with a retry action', (tester) async {
    await tester.pumpWidget(
      _testApp(rankingStream: Stream.error(StateError('temporary failure'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load ranking'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('opens a Normal challenge request from the ladder', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Challenge Opponent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Normal challenge'));
    await tester.pumpAndSettle();

    expect(find.text('Create Normal challenge?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('navigates to the signed-in profile', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Tugume Keith'), findsOneWidget);
    expect(find.text('Signed in with your MUKLadder account.'), findsOneWidget);
  });

  testWidgets('shows profile photos on ladder and player profile', (
    tester,
  ) async {
    const photoUrl = 'https://example.com/player.jpg';
    await tester.pumpWidget(
      _testApp(profilePhotoUrl: photoUrl, rankingPhotoUrl: photoUrl),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is PlayerAvatar && widget.photoUrl == photoUrl,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PlayerAvatar && widget.photoUrl == photoUrl,
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows match scores and opponents in player profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        matchHistory: [
          PlayerMatchHistoryEntry(
            challengeId: 'challenge-history',
            opponentName: 'Opponent',
            score: '6-4, 6-3',
            status: ResultStatus.confirmed,
            challengeType: ChallengeType.normal,
            playedAt: DateTime(2026, 11, 4),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Match history'), findsOneWidget);
    expect(find.text('vs Opponent'), findsOneWidget);
    expect(
      find.text('Score: 6-4, 6-3 · Confirmed · 4/11/2026'),
      findsOneWidget,
    );
  });

  testWidgets('accepts an incoming challenge', (tester) async {
    await tester.pumpWidget(_testApp(challenges: [_incomingChallenge]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Challenges').last);
    await tester.pumpAndSettle();

    expect(find.text('Incoming Normal challenge'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Challenge accepted.'), findsOneWidget);
  });

  testWidgets('submits and confirms an accepted match result', (tester) async {
    final challengeRepository = InMemoryChallengeRepository(
      challenges: [_acceptedChallenge],
    );
    final resultRepository = InMemoryResultRepository(
      challengeRepository: challengeRepository,
    );
    await tester.pumpWidget(
      _testApp(
        currentUserId: 'demo-player-1',
        challengeRepository: challengeRepository,
        resultRepository: resultRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Challenges').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit result'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '4-6, 3-6');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Result: 4-6, 3-6 (submitted)'), findsOneWidget);
    await tester.pumpWidget(
      _testApp(
        currentUserId: 'player-2',
        challengeRepository: challengeRepository,
        resultRepository: resultRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Challenges').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Result: 4-6, 3-6 (confirmed)'), findsOneWidget);
  });

  testWidgets('opens the role-protected admin overview', (tester) async {
    await tester.pumpWidget(
      _testApp(
        role: AppRole.admin,
        adminOverview: const AdminOverview(
          totalPlayers: 24,
          activePlayers: 22,
          pendingChallenges: 3,
          unresolvedResults: 1,
          auditEvents: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Open admin workspace'), 300);
    await tester.tap(find.text('Open admin workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Tournament operations'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Administrative actions are read-only'), findsOneWidget);
  });
}

Widget _testApp({
  AppRole role = AppRole.player,
  String currentUserId = 'demo-player-1',
  String? profilePhotoUrl,
  String? rankingPhotoUrl,
  Iterable<Challenge> challenges = const [],
  InMemoryChallengeRepository? challengeRepository,
  InMemoryResultRepository? resultRepository,
  Stream<List<RankingEntry>>? rankingStream,
  AdminOverview? adminOverview,
  List<PlayerMatchHistoryEntry> matchHistory = const [],
}) {
  final challengeRepo =
      challengeRepository ??
      InMemoryChallengeRepository(challenges: challenges);
  final resultsRepo =
      resultRepository ??
      InMemoryResultRepository(challengeRepository: challengeRepo);
  return ProviderScope(
    key: ValueKey(currentUserId),
    overrides: [
      currentUserProvider.overrideWithValue(
        AppUser(
          id: currentUserId,
          displayName: 'Tugume Keith',
          role: role,
          photoUrl: profilePhotoUrl,
        ),
      ),
      rankingProvider.overrideWith(
        (ref) =>
            rankingStream ??
            Stream.value(
              _rankingEntries
                  .map(
                    (entry) => RankingEntry(
                      position: entry.position,
                      player: Player(
                        id: entry.player.id,
                        displayName: entry.player.displayName,
                        lastActivityAt: entry.player.lastActivityAt,
                        photoUrl: entry.player.id == 'player-2'
                            ? rankingPhotoUrl
                            : entry.player.photoUrl,
                      ),
                    ),
                  )
                  .toList(),
            ),
      ),
      challengeRepositoryProvider.overrideWith((ref) => challengeRepo),
      resultRepositoryProvider.overrideWith((ref) => resultsRepo),
      playerMatchHistoryProvider(currentUserId)
          .overrideWith((ref) async => matchHistory),
      notificationRepositoryProvider.overrideWith(
        (ref) => InMemoryNotificationRepository(),
      ),
      if (adminOverview != null)
        adminOverviewProvider.overrideWith((ref) async => adminOverview),
    ],
    child: const MukladderApp(),
  );
}

final _rankingEntries = [
  RankingEntry(
    position: 1,
    player: Player(
      id: 'player-2',
      displayName: 'Opponent',
      lastActivityAt: DateTime(2026, 11, 3),
    ),
  ),
  RankingEntry(
    position: 2,
    player: Player(
      id: 'demo-player-1',
      displayName: 'Tugume Keith',
      lastActivityAt: DateTime(2026, 11, 4),
    ),
  ),
];

final _incomingChallenge = Challenge(
  id: 'challenge-incoming',
  challengerId: 'player-3',
  challengedId: 'demo-player-1',
  type: ChallengeType.normal,
  status: ChallengeStatus.pending,
  createdAt: DateTime.now(),
);

final _acceptedChallenge = Challenge(
  id: 'challenge-accepted',
  challengerId: 'demo-player-1',
  challengedId: 'player-2',
  type: ChallengeType.normal,
  status: ChallengeStatus.accepted,
  createdAt: DateTime.now(),
);
