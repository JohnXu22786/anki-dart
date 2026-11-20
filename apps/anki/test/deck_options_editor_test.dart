// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_app/deck_options_editor.dart';
import 'package:anki_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows limits, saves edits, and reports storage failures', (
    tester,
  ) async {
    var newLimit = 32;
    var reviewLimit = 215;
    var fail = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => DeckOptionsEditor(
                  deckName: 'Languages',
                  initialNewPerDay: newLimit,
                  initialReviewsPerDay: reviewLimit,
                  onSave: (newPerDay, reviewsPerDay) async {
                    if (fail) throw StateError('write failed');
                    newLimit = newPerDay;
                    reviewLimit = reviewsPerDay;
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('32'), findsOneWidget);
    expect(find.text('215'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('deck-new-limit')),
      '10000',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('deck-new-limit')))
          .controller!
          .text,
      '10000',
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter whole numbers between 0 and 9999.'),
      findsOneWidget,
    );
    expect(newLimit, 32);

    await tester.enterText(find.byKey(const ValueKey('deck-new-limit')), '40');
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('deck-review-limit')),
      '250',
    );
    await tester.pump();
    fail = true;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save deck options.'), findsOneWidget);
    expect(find.byType(DeckOptionsEditor), findsOneWidget);
    expect(newLimit, 32);

    fail = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(newLimit, 40);
    expect(reviewLimit, 250);
    expect(find.byType(DeckOptionsEditor), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const ValueKey('deck-new-limit')), '040');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckOptionsEditor), findsNothing);
  });
}
