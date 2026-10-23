import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukladder/app/app.dart';
import 'package:mukladder/features/ladder/application/ranking_providers.dart';
import 'package:mukladder/features/ladder/domain/ranking_entry.dart';
import 'package:mukladder/features/players/domain/player.dart';

void main() {
  testWidgets('shows the demo ladder shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MukladderApp()));
    await tester.pumpAndSettle();

    expect(find.text('MUKLadder'), findsOneWidget);
    expect(find.text('Welcome, Demo Player'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
    expect(find.text('Live ranking'), findsOneWidget);
    expect(find.text('Joel Niwamanya'), findsOneWidget);
    expect(find.text('Ladder'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('shows a loading state while ranking data is requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankingProvider.overrideWith(
            (ref) => Future<List<RankingEntry>>.delayed(
              const Duration(seconds: 1),
              () => [
                RankingEntry(
                  position: 1,
                  player: Player(
                    id: 'player-1',
                    displayName: 'Demo Player',
                    lastActivityAt: DateTime(2026, 10, 23),
                  ),
                ),
              ],
            ),
          ),
        ],
        child: const MukladderApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('shows an empty state when there are no ranking entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankingProvider.overrideWith((ref) async => <RankingEntry>[]),
        ],
        child: const MukladderApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No ranking data yet'), findsOneWidget);
  });

  testWidgets('shows an error state and retries ranking data', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankingProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) {
              throw StateError('temporary failure');
            }
            return demoRankingEntries;
          }),
        ],
        child: const MukladderApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load ranking'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Joel Niwamanya'), findsOneWidget);
  });

  testWidgets('navigates to the demo profile', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MukladderApp()));

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Demo identity'), findsOneWidget);
    expect(
      find.text(
        'Firebase authentication will replace this temporary identity.',
      ),
      findsOneWidget,
    );
  });
}
