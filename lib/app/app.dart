import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';

import 'app_brand.dart';
import '../features/admin/application/admin_overview_provider.dart';
import '../features/admin/application/admin_notification_providers.dart';
import '../features/admin/application/admin_registration_providers.dart';
import '../features/admin/domain/admin_player_points.dart';
import '../features/admin/domain/pending_registration.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/domain/app_user.dart';
import '../features/challenges/application/challenge_providers.dart';
import '../features/challenges/domain/challenge.dart';
import '../features/ladder/application/ranking_providers.dart';
import '../features/ladder/domain/ranking_entry.dart';
import '../features/membership/application/membership_providers.dart';
import '../features/notifications/application/notification_providers.dart';
import '../features/notifications/domain/notification.dart';
import '../features/players/data/firebase_profile_photo_repository.dart';
import '../features/results/application/result_providers.dart';
import '../features/results/domain/match_result.dart';
import '../features/results/domain/player_match_history_entry.dart';
import '../features/players/presentation/player_avatar.dart';

class MukladderApp extends ConsumerStatefulWidget {
  const MukladderApp({super.key});

  @override
  ConsumerState<MukladderApp> createState() => _MukladderAppState();
}

class _MukladderAppState extends ConsumerState<MukladderApp>
    with WidgetsBindingObserver {
  Timer? _activityTimer;
  String? _activityUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startActivityTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startActivityTracking();
    } else {
      _activityTimer?.cancel();
      _activityTimer = null;
    }
  }

  void _startActivityTracking() {
    _activityTimer?.cancel();
    unawaited(_recordActivity());
    _activityTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_recordActivity()),
    );
  }

  Future<void> _recordActivity() async {
    try {
      await ref.read(authServiceProvider).recordActivity();
    } on FirebaseException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while recording player activity'),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user == null) {
          _activityUserId = null;
        } else if (_activityUserId != user.id) {
          _activityUserId = user.id;
          unawaited(_recordActivity());
        }
      });
    });
    return MaterialApp.router(
      title: 'MUKLadder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5D3B),
          surface: const Color(0xFFF5F7F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F2),
          foregroundColor: Color(0xFF17362A),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF0B5D3B).withValues(alpha: 0.08),
            ),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B5D3B), width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 3,
          indicatorColor: const Color(0xFF0B5D3B).withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/ladder',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ladder',
              builder: (context, state) => const LadderScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/challenges',
              builder: (context, state) => const ChallengesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
    GoRoute(
      path: '/treasurer',
      builder: (context, state) => const TreasurerScreen(),
    ),
  ],
);

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: user == null
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard),
                  label: 'Ladder',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_tennis_outlined),
                  selectedIcon: Icon(Icons.sports_tennis),
                  label: 'Challenges',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: 'Alerts',
                ),
              ],
            ),
    );
  }
}

class _MembershipCard extends ConsumerStatefulWidget {
  const _MembershipCard({required this.user});

  final AppUser user;

  @override
  ConsumerState<_MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends ConsumerState<_MembershipCard> {
  final _paymentReferenceController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _paymentReferenceController.dispose();
    super.dispose();
  }

  Future<void> _requestMembership() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(membershipApplicationRepositoryProvider)
          .requestToJoinLadder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membership request sent to the Admin.'),
          ),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reportPayment() async {
    final reference = _paymentReferenceController.text.trim();
    if (!RegExp(r'^[A-Za-z0-9-]{4,80}$').hasMatch(reference)) {
      setState(() {
        _error = 'Enter a valid MTN MoMo transaction reference.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(membershipApplicationRepositoryProvider)
          .reportPayment(transactionReference: reference);
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestStatus = widget.user.joinRequestStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              requestStatus == 'paymentReported'
                  ? Icons.hourglass_top_rounded
                  : Icons.sports_tennis,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              switch (requestStatus) {
                'paymentReported' => 'Payment submitted for verification',
                'requested' => 'Complete your ladder membership',
                _ => 'Join the MUKLadder',
              },
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(switch (requestStatus) {
              'paymentReported' =>
                'Your payment reference '
                    '${widget.user.paymentReference ?? 'was submitted'} '
                    'has been sent to the Admin. They must verify the UGX '
                    '40,000 payment before approving your place in the ladder.',
              'requested' =>
                'Your request has been sent to the Admin. The annual ladder '
                    'fee is UGX 40,000. After paying using official instructions, '
                    'submit the MTN MoMo transaction reference below.',
              _ =>
                'Request to join the ladder and pay the annual membership fee '
                    'of UGX 40,000.',
            }, textAlign: TextAlign.center),
            if (requestStatus == 'notRequested') ...[
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'MTN MoMo in-app payment is not configured yet. Tap Join '
                    'Ladder to notify the Admin, then get the official payment '
                    'instructions from them before sending money. The app will '
                    'not charge you.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (requestStatus == 'requested') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _paymentReferenceController,
                enabled: !_busy,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'MTN MoMo transaction reference',
                  helperText: 'Submit only after you have paid UGX 40,000.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _reportPayment,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  _busy ? 'Submitting...' : 'I’ve paid — submit reference',
                ),
              ),
            ] else if (requestStatus == 'notRequested') ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _requestMembership,
                icon: const Icon(Icons.group_add_outlined),
                label: Text(_busy ? 'Sending request...' : 'Join Ladder'),
              ),
            ] else if (requestStatus == 'paymentReported') ...[
              const SizedBox(height: 20),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.hourglass_top_rounded),
                  title: Text('Awaiting Admin verification'),
                  subtitle: Text(
                    'You will be admitted to the ladder after the Admin '
                    'verifies your payment.',
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LadderScreen extends ConsumerWidget {
  const LadderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }
    final isPendingPlayer =
        user.role == AppRole.player && !user.registrationApproved;
    final ranking = isPendingPlayer ? null : ref.watch(rankingProvider);
    final challenges = isPendingPlayer
        ? const <Challenge>[]
        : ref
              .watch(challengesProvider)
              .maybeWhen(data: (items) => items, orElse: () => const []);
    final results = isPendingPlayer
        ? const <MatchResult>[]
        : ref
              .watch(resultsProvider)
              .maybeWhen(data: (items) => items, orElse: () => const []);
    DateTime? cooldownStartedAt;
    for (final result in results) {
      if (result.status != ResultStatus.confirmed) {
        continue;
      }
      final matchingChallenges = challenges.where(
        (item) => item.id == result.challengeId,
      );
      final challenge = matchingChallenges.isEmpty
          ? null
          : matchingChallenges.first;
      if (challenge?.challengerId != user.id) {
        continue;
      }
      if (cooldownStartedAt == null ||
          result.submittedAt.isAfter(cooldownStartedAt)) {
        cooldownStartedAt = result.submittedAt;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (isPendingPlayer) ...[
            Text(
              'Player dashboard',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _MembershipCard(user: user),
            const SizedBox(height: 16),
          ],
          _LadderHero(
            displayName: user.displayName,
            playerPosition: ranking?.maybeWhen(
              data: (entries) => _positionOf(entries, user.id),
              orElse: () => null,
            ),
            playerCount: ranking?.maybeWhen(
              data: (entries) => entries.length,
              orElse: () => null,
            ),
          ),
          const SizedBox(height: 24),
          if (isPendingPlayer) ...[
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Member standings are for approved players'),
                subtitle: Text(
                  'The member list and ladder standings will be available '
                  'after an Admin approves your registration.',
                ),
              ),
            ),
          ] else ...[
            Text(
              'Current standings',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Standings follow the ranking feed configured for this tournament.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ranking!.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) =>
                  _RankingError(onRetry: () => ref.invalidate(rankingProvider)),
              data: (entries) => entries.isEmpty
                  ? const _EmptyRanking()
                  : _RankingList(
                      entries: entries,
                      currentUserId: user.id,
                      cooldownStartedAt: cooldownStartedAt,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({
    required this.entries,
    required this.currentUserId,
    required this.cooldownStartedAt,
  });

  final List<RankingEntry> entries;
  final String currentUserId;
  final DateTime? cooldownStartedAt;

  @override
  Widget build(BuildContext context) {
    final currentPosition = _positionOf(entries, currentUserId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.map((entry) {
          final isCurrentPlayer = entry.player.id == currentUserId;
          final canChallenge = !isCurrentPlayer && currentPosition != null;
          return Card(
            color: isCurrentPlayer
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: SizedBox(
                width: 84,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RankBadge(position: entry.position),
                    const SizedBox(width: 4),
                    PlayerAvatar(
                      displayName: entry.player.displayName,
                      photoUrl: entry.player.photoUrl,
                      radius: 19,
                    ),
                  ],
                ),
              ),
              title: Text(
                entry.player.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                entry.player.lastActivityAt == null
                    ? 'No recorded activity'
                    : 'Last active ${_formatDate(entry.player.lastActivityAt!)}',
              ),
              trailing: canChallenge
                  ? PopupMenuButton<String>(
                      tooltip: 'Challenge ${entry.player.displayName}',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == 'normal') {
                          _showChallengeDialog(
                            context,
                            entry,
                            currentUserId,
                            currentPosition,
                            cooldownStartedAt,
                          );
                        } else {
                          _createGodChallenge(context, entry, currentUserId);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'normal',
                          child: Text('Normal challenge'),
                        ),
                        PopupMenuItem(
                          value: 'god',
                          child: Text('G.O.D. challenge'),
                        ),
                      ],
                    )
                  : Text(
                      isCurrentPlayer ? 'You' : 'Join the ladder to challenge',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _createGodChallenge(
    BuildContext context,
    RankingEntry entry,
    String currentUserId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create G.O.D. challenge?'),
        content: Text(
          'Send a G.O.D. challenge to ${entry.player.displayName}? '
          'The challenge will require their mutual consent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send G.O.D. challenge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final proposedDate = await _chooseMatchDate(context);
    if (proposedDate == null || !context.mounted) {
      return;
    }

    try {
      final container = ProviderScope.containerOf(context);
      await container.read(
        godChallengeCreationProvider(
          GodChallengeRequest(
            challengerId: currentUserId,
            challengedId: entry.player.id,
            createdAt: DateTime.now(),
            proposedDate: proposedDate,
          ),
        ).future,
      );
      container.invalidate(challengesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'G.O.D. challenge sent to ${entry.player.displayName}.',
            ),
          ),
        );
      }
    } on ArgumentError catch (error) {
      if (context.mounted) {
        _showChallengeError(context, error.message.toString());
      }
    } on StateError catch (error) {
      if (context.mounted) {
        _showChallengeError(context, error.message);
      }
    }
  }

  Future<void> _showChallengeDialog(
    BuildContext context,
    RankingEntry entry,
    String currentUserId,
    int currentUserPosition,
    DateTime? cooldownStartedAt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Normal challenge?'),
        content: Text(
          'Send a challenge to ${entry.player.displayName}? '
          'You can follow its status from the Challenges tab.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send challenge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final proposedDate = await _chooseMatchDate(context);
    if (proposedDate == null || !context.mounted) {
      return;
    }

    final container = ProviderScope.containerOf(context);
    final createdAt = DateTime.now();
    final request = ChallengeRequest(
      challengerId: currentUserId,
      challengedId: entry.player.id,
      createdAt: createdAt,
      challengerPosition: currentUserPosition,
      challengedPosition: entry.position,
      proposedDate: proposedDate,
      cooldownStartedAt: cooldownStartedAt,
    );
    try {
      await container.read(challengeCreationProvider(request).future);
      container.invalidate(challengesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge sent to ${entry.player.displayName}'),
          ),
        );
      }
    } on ArgumentError catch (error) {
      if (context.mounted) {
        _showChallengeError(context, error.message.toString());
      }
    } on StateError catch (error) {
      if (context.mounted) {
        _showChallengeError(context, error.message);
      }
    }
  }

  void _showChallengeError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} at $hour:$minute';
  }
}

Future<DateTime?> _chooseMatchDate(BuildContext context) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final lastAllowedDay = DateTime(now.year, now.month, now.day + 3);
  return showDatePicker(
    context: context,
    initialDate: tomorrow,
    firstDate: tomorrow,
    lastDate: lastAllowedDay,
    helpText: 'Choose a match date (within 3 days)',
  );
}

int? _positionOf(List<RankingEntry> entries, String playerId) {
  for (final entry in entries) {
    if (entry.player.id == playerId) {
      return entry.position;
    }
  }
  return null;
}

class _LadderHero extends StatelessWidget {
  const _LadderHero({
    required this.displayName,
    required this.playerPosition,
    required this.playerCount,
  });

  final String displayName;
  final int? playerPosition;
  final int? playerCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B5D3B), Color(0xFF174B39)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B5D3B).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBrandMark(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'MAKERERE UNIVERSITY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Icon(Icons.sports_tennis, color: Color(0xFFD8F06A)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome back,',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(
                label: 'YOUR RANK',
                value: playerPosition == null ? '—' : '#$playerPosition',
              ),
              const SizedBox(width: 28),
              _HeroStat(
                label: 'PLAYERS',
                value: playerCount?.toString() ?? '—',
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: colors.tertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlighted = position <= 3;
    return CircleAvatar(
      radius: 19,
      backgroundColor: highlighted
          ? colors.tertiaryContainer
          : colors.surfaceContainerHighest,
      foregroundColor: highlighted
          ? colors.onTertiaryContainer
          : colors.onSurfaceVariant,
      child: Text(
        '$position',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.people_outline),
        title: Text('No ranking data yet'),
        subtitle: Text(
          'Players will appear here when the ladder is populated.',
        ),
      ),
    );
  }
}

class _RankingError extends StatelessWidget {
  const _RankingError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('Unable to load ranking'),
        subtitle: const Text('Please try again.'),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}

String _profilePhotoError(FirebaseException error) {
  if (error.plugin == 'cloud_firestore') {
    if (error.code == 'permission-denied') {
      return 'Firebase Authentication may have created your account, but '
          'Firestore blocked saving the player profile. Publish the current '
          'firestore.rules to project mukladder-4351c, then sign in again to '
          'finish setup.';
    }
    return 'Firestore could not save the account profile '
        '(${error.code}: ${error.message ?? 'no additional details'}).';
  }
  if (error.plugin == 'firebase_storage') {
    return switch (error.code) {
      'object-not-found' =>
        'Firebase Storage cannot find this photo in the configured bucket. '
            'Ask the project owner to confirm or create the bucket configured '
            'for this app, then check Storage > Files for the uploaded photo.',
      'bucket-not-found' =>
        'The Firebase Storage bucket is not available. Ask the project '
            'owner to enable the configured bucket.',
      'unauthorized' || 'unauthenticated' =>
        'Firebase Storage rejected this upload. Check that you are signed '
            'in and that the deployed Storage rules allow your own photo.',
      _ => error.message ?? 'Could not upload the profile photo.',
    };
  }
  return error.message ?? 'Could not save your account or profile photo.';
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Center(child: _ProfilePhotoEditor(user: user)),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(user.role.label, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _PlayerMatchHistorySection(userId: user.id),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Account'),
              subtitle: Text('Signed in with your MUKLadder account.'),
            ),
          ),
          if (user.role == AppRole.admin) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Open admin workspace'),
            ),
          ],
          if (user.role == AppRole.treasurer) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/treasurer'),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Open treasurer workspace'),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _PlayerMatchHistorySection extends ConsumerWidget {
  const _PlayerMatchHistorySection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(playerMatchHistoryProvider(userId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        history.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Unable to load match history'),
              subtitle: Text(error.toString()),
              trailing: IconButton(
                tooltip: 'Retry match history',
                onPressed: () =>
                    ref.invalidate(playerMatchHistoryProvider(userId)),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
          data: (entries) => entries.isEmpty
              ? const Card(
                  child: ListTile(
                    leading: Icon(Icons.sports_tennis_outlined),
                    title: Text('No match history yet'),
                    subtitle: Text(
                      'Confirmed and submitted match scores will appear here.',
                    ),
                  ),
                )
              : Column(
                  children: entries
                      .map((entry) => _MatchHistoryCard(entry: entry))
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}

class _MatchHistoryCard extends StatelessWidget {
  const _MatchHistoryCard({required this.entry});

  final PlayerMatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = entry.playedAt.toLocal();
    final dateLabel = '${date.day}/${date.month}/${date.year}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sports_tennis_outlined),
        title: Text('vs ${entry.opponentName}'),
        subtitle: Text(
          'Score: ${entry.score} · ${entry.statusLabel} · $dateLabel',
        ),
        isThreeLine: true,
        trailing: Text(
          entry.challengeTypeLabel,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _ProfilePhotoEditor extends ConsumerStatefulWidget {
  const _ProfilePhotoEditor({required this.user});

  final AppUser user;

  @override
  ConsumerState<_ProfilePhotoEditor> createState() =>
      _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends ConsumerState<_ProfilePhotoEditor> {
  final _picker = ImagePicker();
  String? _photoUrl;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.user.photoUrl;
  }

  Future<void> _choosePhoto() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.length > FirebaseProfilePhotoRepository.maximumPhotoSizeBytes) {
        setState(() => _error = 'Choose a photo no larger than 5 MB.');
        return;
      }

      final updatedUser = await ref
          .read(authServiceProvider)
          .updateProfilePhoto(profilePhoto: bytes);
      if (!mounted) {
        return;
      }
      setState(() => _photoUrl = updatedUser.photoUrl);
      ref.invalidate(authStateProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } on PlatformException {
      if (mounted) {
        setState(() => _error = 'Could not open the photo gallery.');
      }
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        setState(() => _error = error.message?.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlayerAvatar(
          displayName: widget.user.displayName,
          photoUrl: _photoUrl,
          radius: 42,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _choosePhoto,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_camera_outlined),
          label: Text(_busy ? 'Uploading...' : 'Change profile photo'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _AuthenticationRequiredScreen extends StatelessWidget {
  const _AuthenticationRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return const AuthScreen();
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _registering = false;
  AppRole _signInRole = AppRole.player;
  bool _busy = false;
  String? _error;
  Uint8List? _selectedProfilePhoto;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickSignupPhoto() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      if (bytes.length > FirebaseProfilePhotoRepository.maximumPhotoSizeBytes) {
        if (mounted) {
          setState(() => _error = 'Choose a photo no larger than 5 MB.');
        }
        return;
      }
      if (mounted) {
        setState(() => _selectedProfilePhoto = bytes);
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _error = 'Could not open the photo gallery.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();
    if (!email.contains('@') || password.length < 6) {
      setState(
        () => _error =
            'Enter a valid email and a password of at least 6 characters.',
      );
      return;
    }
    if (_registering && displayName.isEmpty) {
      setState(() => _error = 'Enter your display name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(authServiceProvider);
      if (_registering) {
        await service.register(
          email: email,
          password: password,
          displayName: displayName,
          profilePhoto: _selectedProfilePhoto,
        );
        ref.invalidate(authStateProvider);
        if (mounted) {
          context.go('/ladder');
        }
      } else {
        final user = await service.signIn(email: email, password: password);
        if (user.role != _signInRole) {
          await service.signOut();
          throw StateError(
            'This account is registered as ${user.role.label}. '
            'Choose ${user.role.label} sign-in and try again.',
          );
        }
        if (mounted) {
          context.go(switch (user.role) {
            AppRole.admin => '/admin',
            AppRole.treasurer => '/treasurer',
            AppRole.player => '/ladder',
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = _authErrorMessage(error));
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = _profilePhotoError(error));
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        setState(() => _error = error.message?.toString());
      }
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    final backendConfigurationMissing =
        error.message?.toUpperCase().contains('CONFIGURATION_NOT_FOUND') ??
        false;
    if (error.code == 'configuration-not-found' ||
        backendConfigurationMissing) {
      return 'Firebase Authentication is not fully configured for project '
          'mukladder-4351c. In Firebase Console open Authentication, finish '
          'setting it up, then enable Email/Password under Sign-in method. '
          'Confirm the Android app is registered in this same project.';
    }

    return switch (error.code) {
      'email-already-in-use' =>
        'That email already has an Authentication account. Sign in instead. '
            'If its player profile was not saved earlier, signing in will retry '
            'the profile setup.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'weak-password' => 'Choose a stronger password (at least 6 characters).',
      'invalid-email' => 'Enter a valid email address.',
      'operation-not-allowed' =>
        'Email/Password sign-up is not enabled for Firebase project '
            'mukladder-4351c. In Firebase Console open Authentication > '
            'Sign-in method and enable Email/Password.',
      'network-request-failed' =>
        'Firebase could not reach the network. Check the tablet’s internet '
            'connection and try again.',
      'too-many-requests' =>
        'Firebase temporarily blocked requests from this device. Wait a few '
            'minutes and try again.',
      'app-not-authorized' || 'invalid-api-key' =>
        'This Android app is not authorized by the Firebase project. Verify '
            'the registered Android package and API key configuration.',
      _ =>
        'Firebase Authentication failed (${error.code}). '
            '${error.message ?? 'Check Authentication > Sign-in method and '
                    'the Firebase project configuration, then try again.'}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          const Center(child: AppBrandMark(size: 84)),
          const SizedBox(height: 20),
          Text(
            'Your ladder. Your game.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to follow rankings and manage your challenges.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          if (!_registering) ...[
            SegmentedButton<AppRole>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: AppRole.player, label: Text('Player')),
                ButtonSegment(value: AppRole.admin, label: Text('Admin')),
                ButtonSegment(
                  value: AppRole.treasurer,
                  label: Text('Treasurer'),
                ),
              ],
              selected: {_signInRole},
              onSelectionChanged: _busy
                  ? null
                  : (selection) {
                      setState(() {
                        _signInRole = selection.single;
                        _error = null;
                      });
                    },
            ),
            const SizedBox(height: 8),
            Text(
              'Admin and Treasurer access must be assigned by the project '
              'owner. The selected role is checked after sign-in.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          if (_registering) ...[
            Center(
              child: Column(
                children: [
                  PlayerAvatar(
                    displayName: _displayNameController.text,
                    photoBytes: _selectedProfilePhoto,
                    radius: 36,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickSignupPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _selectedProfilePhoto == null
                          ? 'Add profile photo (optional)'
                          : 'Change profile photo',
                    ),
                  ),
                  const Text('JPG image, up to 5 MB'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              _busy
                  ? 'Please wait...'
                  : _registering
                  ? 'Create account'
                  : 'Sign in',
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _registering = !_registering;
                    _signInRole = AppRole.player;
                    _error = null;
                  }),
            child: Text(
              _registering
                  ? 'Already have an account? Sign in'
                  : 'New player? Create an account',
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load alerts.')),
        data: (snapshot) => snapshot.notifications.isEmpty
            ? _NotificationStateView(snapshot: snapshot)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _NotificationSyncBanner(snapshot: snapshot),
                  for (final notification in snapshot.notifications)
                    _NotificationTile(notification: notification),
                ],
              ),
      ),
    );
  }
}

class _NotificationStateView extends StatelessWidget {
  const _NotificationStateView({required this.snapshot});

  final NotificationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NotificationSyncBanner(snapshot: snapshot),
        const SizedBox(height: 24),
        const Center(child: Text('No alerts yet.')),
      ],
    );
  }
}

class _NotificationSyncBanner extends StatelessWidget {
  const _NotificationSyncBanner({required this.snapshot});

  final NotificationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final message = switch (snapshot.state) {
      NotificationSyncState.synchronized => 'Saved on this device',
      NotificationSyncState.stale => 'These alerts may be out of date',
      NotificationSyncState.offline => 'Offline: showing saved alerts',
      NotificationSyncState.rejected =>
        snapshot.rejectedWrite ?? 'Alert storage was rejected',
    };
    return Card(
      color: snapshot.state == NotificationSyncState.synchronized
          ? null
          : Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.sync_problem_outlined),
        title: Text(message),
        subtitle: snapshot.lastSyncedAt == null
            ? null
            : Text('Last saved: ${snapshot.lastSyncedAt}'),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active,
        ),
        title: Text(notification.title),
        subtitle: Text(notification.body),
      ),
    );
  }
}

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }
    if (user.role != AppRole.admin) {
      return const _RoleDeniedScreen(requiredRole: AppRole.admin);
    }

    final overview = ref.watch(adminOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandLockup(compact: true),
        actions: [
          IconButton(
            tooltip: 'Refresh admin overview',
            onPressed: () => ref.invalidate(adminOverviewProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 40),
                const SizedBox(height: 12),
                const Text('Unable to load the admin overview.'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(adminOverviewProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Tournament operations',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'A live overview of players, challenges, results, and activity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const _AdminMembershipAlerts(),
            const SizedBox(height: 12),
            const _PendingRegistrationQueue(),
            const SizedBox(height: 12),
            _AdminSummaryCard(
              title: 'Active players',
              subtitle: '${data.totalPlayers} registered players',
              icon: Icons.groups_2_outlined,
              value: '${data.activePlayers}',
            ),
            _AdminSummaryCard(
              title: 'Pending challenges',
              subtitle: 'Awaiting a player response',
              icon: Icons.sports_tennis_outlined,
              value: '${data.pendingChallenges}',
            ),
            _AdminSummaryCard(
              title: 'Results to review',
              subtitle: 'Submitted or disputed results',
              icon: Icons.fact_check_outlined,
              value: '${data.unresolvedResults}',
            ),
            _AdminSummaryCard(
              title: 'Audit events',
              subtitle: 'Recorded tournament activity',
              icon: Icons.history,
              value: '${data.auditEvents}',
            ),
            const SizedBox(height: 12),
            const _AdminPlayerPointsSection(),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Ladder positions remain protected'),
                subtitle: Text(
                  'Manual points are tracked separately and do not change '
                  'ladder positions. Match-result ranking decisions still '
                  'require confirmed rules and trusted backend workflows.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMembershipAlerts extends ConsumerWidget {
  const _AdminMembershipAlerts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(adminNotificationsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Membership alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            notifications.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => const Text(
                'Unable to load Admin alerts. Refresh to try again.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.notifications_none),
                    title: Text('No new membership alerts'),
                  );
                }
                return Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notifications_active),
                          title: Text(item.title),
                          subtitle: Text(item.body),
                          isThreeLine: true,
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRegistrationQueue extends ConsumerWidget {
  const _PendingRegistrationQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRegistrationsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending registrations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Verify the UGX 40,000 payment, then assign an initial position.',
            ),
            const SizedBox(height: 8),
            pending.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Column(
                children: [
                  const Text('Unable to load pending registrations.'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(pendingRegistrationsProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
              data: (registrations) {
                if (registrations.isEmpty) {
                  return const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('No pending registrations'),
                  );
                }
                return Column(
                  children: registrations
                      .map(
                        (registration) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PlayerAvatar(
                            displayName: registration.displayName,
                            photoUrl: registration.photoUrl,
                            radius: 22,
                          ),
                          title: Text(registration.displayName),
                          subtitle: Text(
                            [
                              if (registration.email.isNotEmpty)
                                registration.email,
                              if (registration.paymentReported)
                                'Payment reference: '
                                    '${registration.paymentReference ?? 'not available'} '
                                    '(verify in MTN MoMo)',
                              if (!registration.paymentReported)
                                'Request received; awaiting payment report',
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: registration.paymentReported
                              ? FilledButton(
                                  onPressed: () => _approveRegistration(
                                    context,
                                    ref,
                                    registration,
                                  ),
                                  child: const Text('Review'),
                                )
                              : const Chip(label: Text('Awaiting payment')),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRegistration(
    BuildContext context,
    WidgetRef ref,
    PendingRegistration registration,
  ) async {
    try {
      final repository = ref.read(adminRegistrationRepositoryProvider);
      final suggestedPosition = await repository.suggestedPosition();
      if (!context.mounted) {
        return;
      }
      final controller = TextEditingController(
        text: suggestedPosition.toString(),
      );
      final initialPosition = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          var paymentVerified = false;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Verify payment and assign position'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm that ${registration.displayName} paid '
                    'UGX ${PendingRegistration.membershipFeeDisplay}. '
                    'Verify reference ${registration.paymentReference ?? 'not available'} '
                    'in MTN MoMo before approving. '
                    'The ladder currently has positions 1 to '
                    '${suggestedPosition - 1}.',
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: paymentVerified,
                    onChanged: (value) {
                      setDialogState(() => paymentVerified = value ?? false);
                    },
                    title: const Text('I verified this payment externally'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Initial position',
                      helperText: 'Choose 1 to $suggestedPosition',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: paymentVerified
                      ? () {
                          final value = int.tryParse(controller.text);
                          if (value != null &&
                              value > 0 &&
                              value <= suggestedPosition) {
                            Navigator.pop(dialogContext, value);
                          }
                        }
                      : null,
                  child: const Text('Verify payment & approve'),
                ),
              ],
            ),
          );
        },
      );
      controller.dispose();
      if (initialPosition == null || !context.mounted) {
        return;
      }
      await repository.approveRegistration(
        userId: registration.userId,
        initialPosition: initialPosition,
        paymentVerified: true,
      );
      ref.invalidate(adminOverviewProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${registration.displayName} approved at position '
              '$initialPosition.',
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on ArgumentError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message?.toString() ?? 'Invalid input')),
        );
      }
    }
  }
}

class _AdminPlayerPointsSection extends ConsumerWidget {
  const _AdminPlayerPointsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(adminPlayerPointsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player points',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'View every player’s total or add an audited points adjustment.',
            ),
            const SizedBox(height: 8),
            points.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Column(
                children: [
                  const Text('Unable to load player points.'),
                  TextButton(
                    onPressed: () => ref.invalidate(adminPlayerPointsProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
              data: (players) => players.isEmpty
                  ? const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('No players found'),
                    )
                  : Column(
                      children: players
                          .map((player) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(player.displayName),
                              subtitle: player.canReceivePoints
                                  ? null
                                  : const Text('Pending approval or inactive'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${player.totalPoints} pts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: player.canReceivePoints
                                        ? () => _addPoints(context, ref, player)
                                        : null,
                                    child: const Text('Add points'),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPoints(
    BuildContext context,
    WidgetRef ref,
    AdminPlayerPoints player,
  ) async {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();
    final adjustment = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add points to ${player.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Points to add',
                helperText: 'Use a positive whole number.',
              ),
            ),
            TextField(
              controller: reasonController,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason',
                helperText: 'Required for the audit history.',
              ),
            ),
            const Text(
              'This changes the points total only, not the ladder position.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(pointsController.text);
              final reason = reasonController.text.trim();
              if (amount != null && amount > 0 && reason.isNotEmpty) {
                Navigator.pop(dialogContext, (amount, reason));
              }
            },
            child: const Text('Add points'),
          ),
        ],
      ),
    );
    pointsController.dispose();
    reasonController.dispose();
    if (adjustment == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(adminPointsRepositoryProvider)
          .addPoints(
            playerId: player.playerId,
            points: adjustment.$1,
            reason: adjustment.$2,
          );
      ref.invalidate(adminPlayerPointsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Points added to ${player.displayName}.')),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class TreasurerScreen extends ConsumerWidget {
  const TreasurerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }
    if (user.role != AppRole.treasurer) {
      return const _RoleDeniedScreen(requiredRole: AppRole.treasurer);
    }

    final ranking = ref.watch(rankingProvider);
    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: ranking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load payment overview.')),
        data: (entries) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Payment-status overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment status is a flag only. Payment credentials and '
              'processing are not stored in MUKLadder.',
            ),
            const SizedBox(height: 16),
            ...entries.map(
              (entry) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(entry.player.displayName),
                subtitle: Text('Position ${entry.position}'),
                trailing: Text(entry.player.paymentStatus.name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RoleDeniedScreen extends StatelessWidget {
  const _RoleDeniedScreen({required this.requiredRole});

  final AppRole requiredRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This area is restricted to ${requiredRole.label} users. '
            'Your account does not have permission to view this workspace.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }
    final challenges = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(title: const AppBrandLockup(compact: true)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load challenges.')),
          data: (items) {
            final relevant = items
                .where(
                  (challenge) =>
                      challenge.challengedId == user.id ||
                      challenge.challengerId == user.id,
                )
                .toList();
            if (relevant.isEmpty) {
              return const Center(child: Text('No challenges yet.'));
            }

            return ListView(
              children: relevant
                  .map(
                    (challenge) => _ChallengeCard(
                      challenge: challenge,
                      currentUserId: user.id,
                      result: ref
                          .watch(resultsProvider)
                          .maybeWhen(
                            data: (results) {
                              final matching = results
                                  .where(
                                    (result) =>
                                        result.challengeId == challenge.id,
                                  )
                                  .toList();
                              return matching.isEmpty ? null : matching.first;
                            },
                            orElse: () => null,
                          ),
                      onSubmitResult: () =>
                          _submitResult(context, ref, challenge, user.id),
                      onTransitionResult: (result, status) => _transitionResult(
                        context,
                        ref,
                        result,
                        user.id,
                        status,
                      ),
                      onRespond: (response) =>
                          _respond(context, ref, challenge, user.id, response),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
    String userId,
    ChallengeStatus response,
  ) async {
    DateTime? alternativeDate;
    if (response == ChallengeStatus.alternativeDateProposed) {
      alternativeDate = await _chooseMatchDate(context);
      if (alternativeDate == null || !context.mounted) {
        return;
      }
    }
    try {
      await ref.read(
        challengeResponseProvider(
          ChallengeResponseRequest(
            challengeId: challenge.id,
            respondentId: userId,
            response: response,
            respondedAt: DateTime.now(),
            alternativeDate: alternativeDate,
          ),
        ).future,
      );
      ref.invalidate(challengesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Challenge ${response.name}.')));
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _submitResult(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
    String userId,
  ) async {
    final score = await showDialog<String>(
      context: context,
      builder: (context) => const _ScoreDialog(),
    );
    if (score == null || !context.mounted) {
      return;
    }

    try {
      await ref.read(
        resultSubmissionProvider(
          ResultSubmissionRequest(
            challengeId: challenge.id,
            submittedBy: userId,
            score: score,
            submittedAt: DateTime.now(),
          ),
        ).future,
      );
      ref.invalidate(resultsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Result submitted.')));
      }
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }
      _showResultError(context, error.message);
    } on FormatException catch (error) {
      if (!context.mounted) {
        return;
      }
      _showResultError(context, error.message);
    }
  }

  Future<void> _transitionResult(
    BuildContext context,
    WidgetRef ref,
    MatchResult result,
    String userId,
    ResultStatus status,
  ) async {
    try {
      await ref.read(
        resultTransitionProvider(
          ResultTransitionRequest(
            resultId: result.id,
            actorId: userId,
            status: status,
          ),
        ).future,
      );
      ref.invalidate(resultsProvider);
      ref.invalidate(challengesProvider);
      ref.invalidate(rankingProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Result ${status.name}.')));
      }
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }
      _showResultError(context, error.message);
    }
  }

  void _showResultError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.currentUserId,
    required this.result,
    required this.onSubmitResult,
    required this.onTransitionResult,
    required this.onRespond,
  });

  final Challenge challenge;
  final String currentUserId;
  final MatchResult? result;
  final VoidCallback onSubmitResult;
  final void Function(MatchResult result, ResultStatus status)
  onTransitionResult;
  final ValueChanged<ChallengeStatus> onRespond;

  @override
  Widget build(BuildContext context) {
    final isIncoming = challenge.challengedId == currentUserId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isIncoming ? 'Incoming' : 'Outgoing'} '
              '${challenge.type == ChallengeType.god ? 'G.O.D.' : 'Normal'} '
              'challenge',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Status: ${challenge.status.name}'),
            if (challenge.proposedDate != null)
              Text(
                'Match date: ${_formatChallengeDate(challenge.proposedDate!)}',
              ),
            if (challenge.status == ChallengeStatus.alternativeDateProposed &&
                challenge.alternativeDate != null)
              Text(
                'Proposed alternative: '
                '${_formatChallengeDate(challenge.alternativeDate!)}',
              ),
            if (challenge.status == ChallengeStatus.accepted &&
                result == null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onSubmitResult,
                child: const Text('Submit result'),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 8),
              Text('Result: ${result!.score} (${result!.status.name})'),
              if (result!.status == ResultStatus.submitted &&
                  result!.submittedBy != currentUserId &&
                  (challenge.challengerId == currentUserId ||
                      challenge.challengedId == currentUserId)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () =>
                          onTransitionResult(result!, ResultStatus.confirmed),
                      child: const Text('Confirm'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () =>
                          onTransitionResult(result!, ResultStatus.disputed),
                      child: const Text('Dispute'),
                    ),
                  ],
                ),
              ],
            ],
            if (isIncoming && challenge.status == ChallengeStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => onRespond(ChallengeStatus.accepted),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => onRespond(ChallengeStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
            if (isIncoming && challenge.status == ChallengeStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  onPressed: () =>
                      onRespond(ChallengeStatus.alternativeDateProposed),
                  child: const Text('Propose new date'),
                ),
              ),
            if (!isIncoming &&
                challenge.status == ChallengeStatus.alternativeDateProposed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => onRespond(ChallengeStatus.accepted),
                      child: const Text('Accept new date'),
                    ),
                    OutlinedButton(
                      onPressed: () => onRespond(ChallengeStatus.rejected),
                      child: const Text('Reject proposal'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatChallengeDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';

class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog();

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit match result'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Either player can report the score; the opponent reviews it.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Score (challenger first)',
              hintText: '6-4, 6-3',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
