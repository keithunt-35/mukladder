import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/challenges/application/challenge_providers.dart';
import '../features/challenges/domain/challenge.dart';
import '../features/ladder/application/ranking_providers.dart';
import '../features/ladder/domain/ranking_entry.dart';
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
      ],
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
    final ranking = ref.watch(rankingProvider);

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
                : _RankingList(entries: entries, currentUserId: user.id),
          ),
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.entries, required this.currentUserId});

  final List<RankingEntry> entries;
  final String currentUserId;

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
                  ? FilledButton(
                      onPressed: () =>
                          _showChallengeDialog(context, entry, currentUserId),
                      child: const Text('Challenge'),
                    )
                  : const Text('You'),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showChallengeDialog(
    BuildContext context,
    RankingEntry entry,
    String currentUserId,
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
        ],
      ),
    );
  }
}

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
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
