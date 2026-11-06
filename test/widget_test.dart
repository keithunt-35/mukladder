import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mukladder/app/app.dart';
import 'package:mukladder/app/app_brand.dart';
import 'package:mukladder/features/admin/application/admin_overview_provider.dart';
import 'package:mukladder/features/admin/application/admin_notification_providers.dart';
import 'package:mukladder/features/admin/application/admin_registration_providers.dart';
import 'package:mukladder/features/admin/domain/admin_player_points.dart';
import 'package:mukladder/features/admin/domain/admin_overview.dart';
import 'package:mukladder/features/admin/domain/pending_registration.dart';
import 'package:mukladder/features/auth/application/auth_providers.dart';
import 'package:mukladder/features/auth/data/demo_auth_service.dart';
import 'package:mukladder/features/auth/domain/app_user.dart';
import 'package:mukladder/features/membership/application/membership_providers.dart';
import 'package:mukladder/features/membership/data/membership_application_repository.dart';
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
import 'package:mukladder/features/notifications/domain/notification.dart';

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
    expect(find.byType(Banner), findsNothing);
  });

  testWidgets('blocks pending registrations from player features', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(registrationApproved: false));
    await tester.pumpAndSettle();

    expect(find.text('Join the MUKLadder'), findsOneWidget);
    expect(find.text('Join Ladder'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('player can request to join and report an external payment', (
    tester,
  ) async {
    final membershipRepository = _MembershipApplicationRepositoryFake();
    await tester.pumpWidget(
      _testApp(
        registrationApproved: false,
        membershipRepository: membershipRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join Ladder'));
    await tester.pumpAndSettle();
    expect(membershipRepository.joinRequestCount, 1);
    expect(find.textContaining('will not charge you'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        registrationApproved: false,
        joinRequestStatus: 'requested',
        membershipRepository: membershipRepository,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('I’ve paid — submit reference'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'MTN-123456');
    await tester.tap(find.text('I’ve paid — submit reference'));
    await tester.pumpAndSettle();
    expect(membershipRepository.paymentReferences, ['MTN-123456']);
  });

  testWidgets('player waits for Admin verification after reporting payment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        registrationApproved: false,
        joinRequestStatus: 'paymentReported',
        paymentReference: 'MTN-123456',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment submitted for verification'), findsOneWidget);
    expect(find.textContaining('MTN-123456'), findsOneWidget);
    expect(find.text('I’ve paid — submit reference'), findsNothing);
  });

  testWidgets('login lets users choose an expected account role', (
    tester,
  ) async {
    final service = _PlayerOnlyAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((ref) => service)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Treasurer'), findsOneWidget);

    await tester.tap(find.text('Admin'));
    await tester.enterText(find.byType(TextField).at(0), 'admin@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This account is registered as Player'),
      findsOneWidget,
    );
    expect(service.signOutCalls, 1);
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
        playerPoints: const [
          AdminPlayerPoints(
            playerId: 'player-1',
            displayName: 'Player One',
            totalPoints: 15,
            active: true,
            registrationStatus: 'approved',
          ),
          AdminPlayerPoints(
            playerId: 'player-2',
            displayName: 'Player Two',
            totalPoints: 0,
            active: true,
            registrationStatus: 'approved',
          ),
        ],
        pendingRegistrations: const [
          PendingRegistration(
            userId: 'player-3',
            displayName: 'New Member',
            email: 'new@example.com',
            createdAt: null,
            joinRequestStatus: 'paymentReported',
            paymentReference: 'MTN-123456',
          ),
        ],
        adminNotifications: [
          AppNotification(
            id: 'notice-1',
            title: 'Player reported a membership payment',
            body: 'New Member reports payment. Verify the reference.',
            createdAt: DateTime.utc(2026, 11, 6),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Open admin workspace'), 300);
    await tester.tap(find.text('Open admin workspace'));
    await tester.pumpAndSettle();

    final adminScrollable = find.descendant(
      of: find.byType(AdminScreen),
      matching: find.byType(Scrollable),
    );
    expect(find.text('Tournament operations'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Membership alerts'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('Player reported a membership payment'), findsOneWidget);
    expect(find.text('Pending registrations'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('New Member'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('Review'), findsOneWidget);
    expect(find.textContaining('MTN-123456'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Active players'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('22'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pending challenges'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Player points'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('Player points'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Player One'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('Player One'), findsOneWidget);
    expect(find.text('15 pts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Player Two'),
      300,
      scrollable: adminScrollable,
    );
    expect(find.text('Player Two'), findsOneWidget);
    expect(find.text('0 pts'), findsOneWidget);
    expect(find.text('Add points'), findsNWidgets(2));
  });
}

Widget _testApp({
  AppRole role = AppRole.player,
  String currentUserId = 'demo-player-1',
  bool registrationApproved = true,
  String? joinRequestStatus,
  String? paymentReference,
  String? profilePhotoUrl,
  String? rankingPhotoUrl,
  Iterable<Challenge> challenges = const [],
  InMemoryChallengeRepository? challengeRepository,
  InMemoryResultRepository? resultRepository,
  Stream<List<RankingEntry>>? rankingStream,
  AdminOverview? adminOverview,
  List<AdminPlayerPoints> playerPoints = const [],
  List<PendingRegistration> pendingRegistrations = const [],
  List<AppNotification> adminNotifications = const [],
  MembershipApplicationRepository? membershipRepository,
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
          registrationApproved: registrationApproved,
          registrationStatus: registrationApproved ? 'approved' : 'pending',
          joinRequestStatus:
              joinRequestStatus ??
              (registrationApproved ? 'approved' : 'notRequested'),
          paymentReference: paymentReference,
        ),
      ),
      authServiceProvider.overrideWith((ref) => DemoAuthService()),
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
      pendingRegistrationsProvider.overrideWith(
        (ref) => Stream.value(pendingRegistrations),
      ),
      adminNotificationsProvider.overrideWith(
        (ref) => Stream.value(adminNotifications),
      ),
      adminPlayerPointsProvider.overrideWith(
        (ref) => Stream.value(playerPoints),
      ),
      membershipApplicationRepositoryProvider.overrideWith(
        (ref) => membershipRepository ?? _MembershipApplicationRepositoryFake(),
      ),
      if (adminOverview != null)
        adminOverviewProvider.overrideWith((ref) async => adminOverview),
    ],
    child: const MukladderApp(),
  );
}

class _MembershipApplicationRepositoryFake
    implements MembershipApplicationRepository {
  int joinRequestCount = 0;
  final paymentReferences = <String>[];

  @override
  Future<void> requestToJoinLadder() async {
    joinRequestCount++;
  }

  @override
  Future<void> reportPayment({required String transactionReference}) async {
    paymentReferences.add(transactionReference);
  }
}

class _PlayerOnlyAuthService extends DemoAuthService {
  var signOutCalls = 0;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return const AppUser(
      id: 'player-account',
      displayName: 'Player Account',
      role: AppRole.player,
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
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
