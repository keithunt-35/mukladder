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
    expect(find.text('Welcome, Tugume Keith'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
    expect(find.text('Live ranking'), findsOneWidget);
    expect(find.text('Ahimbisibwe Kevin'), findsOneWidget);
    expect(find.text('Ladder'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Challenges'), findsOneWidget);
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
                    displayName: 'Tugume Keith',
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
    expect(find.text('Ahimbisibwe Kevin'), findsOneWidget);
  });

  testWidgets('creates a Normal challenge from the ladder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MukladderApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Challenge').first);
    await tester.pumpAndSettle();
    expect(find.text('Create Normal challenge?'), findsOneWidget);

    await tester.tap(find.text('Send challenge'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
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

  testWidgets('accepts an incoming challenge', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MukladderApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Challenges').last);
    await tester.pumpAndSettle();

    expect(find.text('Incoming Normal challenge'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Challenge accepted.'), findsOneWidget);
  });

  testWidgets('submits and confirms a result for an accepted challenge', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MukladderApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Challenges').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
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
}
