/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/deck_picker_export_dialog.dart';
import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/deck_picker_screen.dart' show DeckPickerDeck;
import 'package:anki_dart/deck_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('format switching shows only source-defined options', (
    tester,
  ) async {
    final requests = <DeckPickerExportDeckRequest>[];
    await tester.pumpWidget(
      _app(
        decks: [DeckPickerDeck(id: 7, name: 'Spanish')],
        selectedDeckId: Int64(7),
        onExport: requests.add,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Include scheduling information'), findsOneWidget);
    expect(find.text('Include deck configurations'), findsOneWidget);
    expect(find.text('Include media'), findsOneWidget);
    expect(find.text('Support older Anki versions'), findsOneWidget);
    expect(find.text('Include tags'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('export-format')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes in plain text (.txt)').last);
    await tester.pumpAndSettle();

    expect(find.text('Include scheduling information'), findsNothing);
    expect(find.text('Include media'), findsNothing);
    expect(find.text('Include tags'), findsOneWidget);
    expect(find.text('Include HTML and media references'), findsOneWidget);
    expect(find.text('Include deck'), findsOneWidget);
    expect(find.text('Include note type'), findsOneWidget);
    expect(find.text('Include GUID'), findsOneWidget);
    expect(find.text('Support older Anki versions'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('export-format')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cards in plain text (.txt)').last);
    await tester.pumpAndSettle();
    expect(find.text('Include HTML and media references'), findsOneWidget);
    expect(find.text('Include tags'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('export-format')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anki collection package (.colpkg)').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('export-deck')), findsNothing);
    expect(find.text('Include media'), findsOneWidget);
    expect(find.text('Support older Anki versions'), findsOneWidget);
    expect(find.text('Include HTML and media references'), findsNothing);
  });

  testWidgets('selected deck and edited options reach the export callback', (
    tester,
  ) async {
    final exactId = Int64.parseInt('9007199254740995');
    final requests = <DeckPickerExportDeckRequest>[];
    await tester.pumpWidget(
      _app(
        decks: [DeckPickerDeck(id: 1, exactId: exactId, name: 'Spanish')],
        selectedDeckId: exactId,
        onExport: requests.add,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('include-deck-configs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.format, DeckPickerExportFormat.apkg);
    expect(requests.single.deckId, exactId);
    expect(requests.single.includeDeckConfigs, isTrue);
    expect(requests.single.includeScheduling, isTrue);
    expect(requests.single.includeMedia, isTrue);
  });

  testWidgets('stale selection starts at All decks and exports whole scope', (
    tester,
  ) async {
    final requests = <DeckPickerExportDeckRequest>[];
    await tester.pumpWidget(
      _app(
        decks: [DeckPickerDeck(id: 7, name: 'Spanish')],
        selectedDeckId: Int64(77),
        onExport: requests.add,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('All decks'), findsOneWidget);
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(requests.single.deckId, isNull);
    expect(requests.single.format, DeckPickerExportFormat.apkg);
  });

  testWidgets('All decks can be selected for a whole-collection export limit', (
    tester,
  ) async {
    final requests = <DeckPickerExportDeckRequest>[];
    await tester.pumpWidget(
      _app(
        decks: [DeckPickerDeck(id: 7, name: 'Spanish')],
        selectedDeckId: Int64(7),
        onExport: requests.add,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('export-deck')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All decks').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(requests.single.deckId, isNull);
    expect(requests.single.format, DeckPickerExportFormat.apkg);
  });
}

Widget _app({
  required List<DeckPickerDeck> decks,
  required Int64? selectedDeckId,
  required ValueChanged<DeckPickerExportDeckRequest> onExport,
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => DeckPickerExportDialog(
              decks: decks,
              selectedDeckId: selectedDeckId,
              onExport: onExport,
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);
