import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    final brandImage = tester.widget<Image>(
      find.descendant(
        of: find.byType(AppBrandMark).first,
        matching: find.byType(Image),
      ),
    );
    expect(brandImage.image, isA<AssetImage>());
    expect((brandImage.image as AssetImage).assetName, appBrandAssetPath);
    expect(find.byType(Banner), findsNothing);
  });

  testWidgets('shows the player dashboard while registration is pending', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(registrationApproved: false));
    await tester.pumpAndSettle();

    expect(find.text('Player dashboard'), findsOneWidget);
    expect(find.text('MAKERERE UNIVERSITY'), findsOneWidget);
    expect(find.text('Join the MUKLadder'), findsOneWidget);
    expect(find.text('Join Ladder'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Member standings are for approved players'),
      300,
      scrollable: find.descendant(
        of: find.byType(LadderScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.text('Member standings are for approved players'),
      findsOneWidget,
    );
    expect(find.text('Current standings'), findsNothing);
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

    await tester.scrollUntilVisible(
      find.text('Join Ladder'),
      300,
      scrollable: find.descendant(
        of: find.byType(LadderScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Join Ladder'));
    await tester.pumpAndSettle();
    expect(membershipRepository.joinRequestCount, 1);
    expect(find.text('Membership request sent to the Admin.'), findsOneWidget);
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

  testWidgets('successful player signup opens the player dashboard', (
    tester,
  ) async {
    final service = _SuccessfulRegistrationAuthService();
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/ladder',
          builder: (context, state) =>
              const Scaffold(body: Text('Player dashboard')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((ref) => service)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final createAccountToggle = find.text('New player? Create an account');
    await _scrollToSignupControl(tester, createAccountToggle);
    await tester.tap(createAccountToggle);
    await tester.pumpAndSettle();
    for (final (index, value) in [
      (0, 'New Player'),
      (1, 'new@example.com'),
      (2, 'password123'),
    ]) {
      final field = find.byType(TextField).at(index);
      await _scrollToSignupControl(tester, field);
      await tester.enterText(field, value);
    }
    final submitButton = find.text('Create account');
    await _scrollToSignupControl(tester, submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(service.registerCalls, 1);
    expect(find.text('Player dashboard'), findsOneWidget);
    router.dispose();
  });

  testWidgets('Admin sign-in opens the Admin dashboard', (tester) async {
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) =>
              const Scaffold(body: Text('Admin dashboard')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => _AdminAuthService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin'));
    await tester.enterText(find.byType(TextField).at(0), 'admin@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Admin dashboard'), findsOneWidget);
    router.dispose();
  });

  testWidgets('explains when Firebase email signup is disabled', (
    tester,
  ) async {
    await _expectSignupError(
      tester,
      FirebaseAuthException(code: 'operation-not-allowed'),
      'Email/Password sign-up is not enabled for Firebase project',
    );
    expect(find.textContaining('enable Email/Password'), findsOneWidget);
  });

  testWidgets('recognizes Firebase configuration missing in unknown error', (
    tester,
  ) async {
    await _expectSignupError(
      tester,
      FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
      ),
      'Firebase Authentication is not fully configured',
    );
    expect(
      find.textContaining('Confirm the Android app is registered'),
      findsOneWidget,
    );
  });

  testWidgets('explains when Firestore blocks saving a new profile', (
    tester,
  ) async {
    await _expectSignupError(
      tester,
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      'Firestore blocked saving the player profile',
    );
    expect(
      find.textContaining('Publish the current firestore.rules'),
      findsOneWidget,
    );
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
            title: 'New ladder membership request',
            body: 'New Member wants to join. Review this player in the Admin workspace.',
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
    expect(find.text('New ladder membership request'), findsOneWidget);
    expect(find.textContaining('Review this player in the Admin workspace'), findsOneWidget);
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

Future<void> _expectSignupError(
  WidgetTester tester,
  Object failure,
  String expectedMessage,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWith(
          (ref) => _FailingSignupAuthService(failure),
        ),
      ],
      child: const MaterialApp(home: AuthScreen()),
    ),
  );
  await tester.pumpAndSettle();

  final createAccountToggle = find.text('New player? Create an account');
  await _scrollToSignupControl(tester, createAccountToggle);
  await tester.tap(createAccountToggle);
  await tester.pumpAndSettle();
  final displayNameField = find.byType(TextField).at(0);
  await _scrollToSignupControl(tester, displayNameField);
  await tester.enterText(displayNameField, 'New Player');
  final emailField = find.byType(TextField).at(1);
  await _scrollToSignupControl(tester, emailField);
  await tester.enterText(emailField, 'new@example.com');
  final passwordField = find.byType(TextField).at(2);
  await _scrollToSignupControl(tester, passwordField);
  await tester.enterText(passwordField, 'password123');
  final submitButton = find.text('Create account');
  await _scrollToSignupControl(tester, submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  expect(find.textContaining(expectedMessage), findsOneWidget);
}

Future<void> _scrollToSignupControl(WidgetTester tester, Finder control) async {
  for (var attempt = 0; attempt < 10 && control.evaluate().isEmpty; attempt++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
  }
  expect(control, findsOneWidget);
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
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

class _SuccessfulRegistrationAuthService extends DemoAuthService {
  var registerCalls = 0;

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    Uint8List? profilePhoto,
  }) async {
    registerCalls++;
    return AppUser(
      id: 'new-player',
      displayName: displayName,
      role: AppRole.player,
      registrationApproved: false,
      registrationStatus: 'notRequested',
      joinRequestStatus: 'notRequested',
    );
  }
}

class _AdminAuthService extends DemoAuthService {
  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => const AppUser(
    id: 'admin-account',
    displayName: 'Ladder Admin',
    role: AppRole.admin,
  );
}

class _FailingSignupAuthService extends DemoAuthService {
  _FailingSignupAuthService(this.failure);

  final Object failure;

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    Uint8List? profilePhoto,
  }) async {
    throw failure;
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
