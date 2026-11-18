/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_app/card_browser_preview.dart';
import 'package:anki_app/card_browser_preview_screen.dart';
import 'package:anki_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one-card preview renders HTML and hides progress controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        () => _session([
          CardBrowserPreviewCard(
            id: BigInt.from(1),
            questionHtml: '<p><strong>Question HTML</strong></p>',
            answerHtml: '<p>Answer HTML</p>',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Question HTML'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('browser-preview-progress')),
      findsNothing,
    );
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('Answer HTML'), findsOneWidget);
  });

  testWidgets('multi-card preview advances, flips and toggles back-side-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        () => _session([
          CardBrowserPreviewCard(
            id: BigInt.from(1),
            questionHtml: '<p>Q1</p>',
            answerHtml: '<p>A1</p>',
          ),
          CardBrowserPreviewCard(
            id: BigInt.from(2),
            questionHtml: '<p>Q2</p>',
            answerHtml: '<p>A2</p>',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 2'), findsOneWidget);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('A1'), findsOneWidget);
    await tester.tap(find.byTooltip('Next card').last);
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);
    expect(find.text('Q2'), findsOneWidget);

    await tester.tap(find.text('Show answers only'));
    await tester.pumpAndSettle();
    expect(find.text('A2'), findsOneWidget);
    await tester.tap(find.text('Show answers only'));
    await tester.pumpAndSettle();
    expect(find.text('Q2'), findsOneWidget);
  });

  testWidgets('keyboard navigation uses the shared model', (tester) async {
    await tester.pumpWidget(
      _app(
        () => _session([
          CardBrowserPreviewCard(
            id: BigInt.from(1),
            questionHtml: '<p>Q1</p>',
            answerHtml: '<p>A1</p>',
          ),
          CardBrowserPreviewCard(
            id: BigInt.from(2),
            questionHtml: '<p>Q2</p>',
            answerHtml: '<p>A2</p>',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('A1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Q2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Q1'), findsOneWidget);
  });

  testWidgets('load failures show a localized recoverable state', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(() {
        attempts++;
        return attempts == 1
            ? Future.error(StateError('stale card'))
            : _session([
                CardBrowserPreviewCard(
                  id: BigInt.from(1),
                  questionHtml: 'Recovered',
                  answerHtml: 'A',
                ),
              ]);
      }),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This preview could not be loaded'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
  });
}

Future<CardBrowserPreviewSession> _session(
  List<CardBrowserPreviewCard> cards,
) async => CardBrowserPreviewSession(cards: cards, currentIndex: 0);

Widget _app(Future<CardBrowserPreviewSession> Function() load) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: CardBrowserPreviewScreen(controller: load),
);
