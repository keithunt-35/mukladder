import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/domain/app_user.dart';
import '../features/challenges/application/challenge_providers.dart';
import '../features/challenges/domain/challenge.dart';
import '../features/ladder/application/ranking_providers.dart';
import '../features/ladder/domain/ranking_entry.dart';
import '../features/notifications/application/notification_providers.dart';
import '../features/notifications/domain/notification.dart';
import '../features/results/application/result_providers.dart';
import '../features/results/domain/match_result.dart';

class MukladderApp extends StatelessWidget {
  const MukladderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MUKLadder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
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

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
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

class LadderScreen extends ConsumerWidget {
  const LadderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }
    final ranking = ref.watch(rankingProvider);
    final challenges = ref
        .watch(challengesProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Challenge>[]);
    final results = ref
        .watch(resultsProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <MatchResult>[]);
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
      appBar: AppBar(
        title: const Text('MUKLadder'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Demo mode',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, ${user.displayName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          ranking.when(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live ranking', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          final canChallenge = entry.player.id != currentUserId;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${entry.position}')),
              title: Text(entry.player.displayName),
              subtitle: Text(
                'Ranking snapshot: ${_formatDate(entry.player.lastActivityAt)}',
              ),
              trailing: canChallenge
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () => _showChallengeDialog(
                            context,
                            entry,
                            currentUserId,
                            entries
                                .firstWhere(
                                  (candidate) =>
                                      candidate.player.id == currentUserId,
                                )
                                .position,
                            cooldownStartedAt,
                          ),
                          child: const Text('Challenge'),
                        ),
                        TextButton(
                          onPressed: () => _createGodChallenge(
                            context,
                            entry,
                            currentUserId,
                          ),
                          child: const Text('G.O.D.'),
                        ),
                      ],
                    )
                  : const Text('You'),
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

    try {
      final container = ProviderScope.containerOf(context);
      await container.read(
        godChallengeCreationProvider(
          GodChallengeRequest(
            challengerId: currentUserId,
            challengedId: entry.player.id,
            createdAt: DateTime.now(),
            proposedDate: DateTime.now().add(const Duration(days: 1)),
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
          'This demo request will remain pending.',
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

    final container = ProviderScope.containerOf(context);
    final request = ChallengeRequest(
      challengerId: currentUserId,
      challengedId: entry.player.id,
      createdAt: DateTime.now(),
      challengerPosition: currentUserPosition,
      challengedPosition: entry.position,
      proposedDate: DateTime.now().add(const Duration(days: 1)),
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
    return '${date.day}/${date.month}/${date.year}';
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const _AuthenticationRequiredScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(user.displayName.substring(0, 1)),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(user.role.label, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Demo identity'),
              subtitle: Text(
                'Firebase authentication will replace this temporary identity.',
              ),
            ),
          ),
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
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
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
        );
      } else {
        await service.signIn(email: email, password: password);
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _authErrorMessage(error.code));
    } on StateError catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _authErrorMessage(String code) => switch (code) {
    'email-already-in-use' => 'That email is already registered.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'The email or password is incorrect.',
    'weak-password' => 'Choose a stronger password.',
    'invalid-email' => 'Enter a valid email address.',
    _ => 'Authentication failed. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MUKLadder sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_registering)
            TextField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
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
      appBar: AppBar(title: const Text('Alerts')),
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

    final challenges = ref.watch(challengesProvider);
    final results = ref.watch(resultsProvider);
    final audits = ref.watch(auditEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin workspace')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Read-only operational overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Administrative mutations require Firebase authorization and '
            'trusted backend transactions.',
          ),
          const SizedBox(height: 16),
          _AdminSummaryCard(
            title: 'Pending challenges',
            icon: Icons.pending_actions,
            value: challenges.maybeWhen(
              data: (items) =>
                  '${items.where((item) => item.status.name == 'pending').length}',
              orElse: () => 'Loading',
            ),
          ),
          _AdminSummaryCard(
            title: 'Unresolved results',
            icon: Icons.rule,
            value: results.maybeWhen(
              data: (items) =>
                  '${items.where((item) => item.status == ResultStatus.submitted || item.status == ResultStatus.disputed).length}',
              orElse: () => 'Loading',
            ),
          ),
          _AdminSummaryCard(
            title: 'Audit events',
            icon: Icons.history,
            value: audits.maybeWhen(
              data: (items) => '${items.length}',
              orElse: () => 'Loading',
            ),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('Treasurer workspace')),
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
    required this.icon,
    required this.value,
  });

  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(value),
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
      appBar: AppBar(title: const Text('Access restricted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This area is restricted to ${requiredRole.label} users. '
            'The current demo identity has no access.',
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
      appBar: AppBar(title: const Text('Challenges')),
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
    try {
      await ref.read(
        challengeResponseProvider(
          ChallengeResponseRequest(
            challengeId: challenge.id,
            respondentId: userId,
            response: response,
            respondedAt: DateTime.now(),
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
              isIncoming ? 'Incoming Normal challenge' : 'Outgoing challenge',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Status: ${challenge.status.name}'),
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
          ],
        ),
      ),
    );
  }
}

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
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Score',
          hintText: '6-4, 6-3',
        ),
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
