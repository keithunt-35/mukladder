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
import 'package:mukladder/features/results/application/result_providers.dart';
import 'package:mukladder/features/results/data/in_memory_result_repository.dart';

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
    await tester.pumpWidget(_testApp(challenges: [_acceptedChallenge]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Challenges').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit result'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '6-4, 6-3');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Result: 6-4, 6-3 (submitted)'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Result: 6-4, 6-3 (confirmed)'), findsOneWidget);
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
  Iterable<Challenge> challenges = const [],
  Stream<List<RankingEntry>>? rankingStream,
  AdminOverview? adminOverview,
}) {
  final challengeRepository = InMemoryChallengeRepository(
    challenges: challenges,
  );
  final resultRepository = InMemoryResultRepository(
    challengeRepository: challengeRepository,
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(
        AppUser(id: 'demo-player-1', displayName: 'Tugume Keith', role: role),
      ),
      rankingProvider.overrideWith(
        (ref) => rankingStream ?? Stream.value(_rankingEntries),
      ),
      challengeRepositoryProvider.overrideWith((ref) => challengeRepository),
      resultRepositoryProvider.overrideWith((ref) => resultRepository),
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
