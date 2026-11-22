/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:anki_app/card_browser_screen.dart';
import 'package:anki_app/card_browser_preview.dart';
import 'package:anki_app/card_browser_preview_screen.dart';
import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/note_editor_screen.dart';
import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('browser deck selector carries exact launch and selection IDs', (
    tester,
  ) async {
    final wideId = Int64.parseInt('9007199254740995');
    final controller = _DeckSelectionController(_sample());
    await tester.pumpWidget(
      _app(controller, const Size(400, 800), launchDeckId: wideId),
    );
    await tester.pumpAndSettle();

    expect(controller.launchDeckId, wideId);
    expect(controller.selectedDeckId, wideId);
    await tester.tap(find.byKey(const ValueKey('browser-selected-deck')));
    await tester.pumpAndSettle();
    expect(find.text('All decks'), findsOneWidget);
    expect(find.byKey(ValueKey('browser-deck-$wideId')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('browser-deck-all')));
    await tester.pumpAndSettle();
    expect(controller.selectionCalls, [null]);
    await tester.tap(find.byKey(const ValueKey('browser-selected-deck')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('browser-deck-$wideId')));
    await tester.pumpAndSettle();

    expect(controller.selectedDeckId, wideId);
    expect(controller.selectionCalls, [null, wideId]);
    await tester.tap(find.byKey(const ValueKey('browser-search-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('browser-filter-deck-$wideId')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('browser-filter-apply')));
    await tester.pumpAndSettle();
    expect(
      controller.submittedRequests.last.filters.decks.single.id,
      BigInt.parse(wideId.toString()),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('browser-heading-question')),
    );
    await tester.tap(find.byKey(const ValueKey('browser-heading-question')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove column'));
    await tester.pumpAndSettle();
    expect(controller.initializeCalls, 1);
    expect(controller.selectedDeckId, wideId);
  });

  testWidgets('note-update undo appears after saving and restores the edit', (
    tester,
  ) async {
    final controller = _EditorController(_sample());
    await tester.pumpWidget(_app(controller, const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-field-0')),
      'edited',
    );
    await tester.tap(find.byKey(const ValueKey('note-editor-save')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsOneWidget,
    );
    expect(find.byTooltip('Undo note edit'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-note-update-undo')));
    await tester.pumpAndSettle();
    expect(controller.undoCalls, 1);
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
  });

  testWidgets('note-update undo is disabled while replay is pending', (
    tester,
  ) async {
    final controller = _EditorController(_sample())..canUndo = true;
    controller.pendingUndo = Completer<void>();
    await tester.pumpWidget(_app(controller, const Size(400, 800)));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-note-update-undo')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
    );
    await tester.pumpAndSettle();
    final item = tester.widget<PopupMenuItem<String>>(
      find.byKey(const ValueKey('browser-note-update-undo')),
    );
    expect(item.enabled, isFalse);
    await tester.tap(find.byKey(const ValueKey('browser-note-update-undo')));
    expect(controller.undoCalls, 1);

    controller.pendingUndo!.complete();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
  });

  testWidgets('undo menu refreshes availability when opened', (tester) async {
    final controller = _EditorController(_sample())..canUndo = true;
    await tester.pumpWidget(_app(controller, const Size(400, 800)));
    await tester.pumpAndSettle();

    controller.canUndo = false;
    await tester.tap(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
    );
    await tester.pumpAndSettle();

    final item = tester.widget<PopupMenuItem<String>>(
      find.byKey(const ValueKey('browser-note-update-undo')),
    );
    expect(item.enabled, isFalse);
    expect(controller.undoCalls, 0);
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
  });

  testWidgets('closed collection during undo reports a browser error', (
    tester,
  ) async {
    final controller = _EditorController(_sample())..canUndo = true;
    await tester.pumpWidget(_app(controller, const Size(400, 800)));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
    );
    await tester.pumpAndSettle();
    controller.collectionClosed = true;
    await tester.tap(find.byKey(const ValueKey('browser-note-update-undo')));
    await tester.pumpAndSettle();

    expect(controller.undoCalls, 0);
    expect(
      find.text('The browser action could not be completed'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
  });

  testWidgets('successful sort refreshes invalidated undo availability', (
    tester,
  ) async {
    final controller = _EditorController(_sample())
      ..canUndo = true
      ..invalidateUndoOnSort = true;
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('browser-sort-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags').last);
    await tester.pumpAndSettle();

    expect(controller.sortedColumns, [BrowserColumn.tags]);
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
  });

  testWidgets(
    'undo failure reports an error and invalidation hides the action',
    (tester) async {
      final controller = _EditorController(_sample())
        ..canUndo = true
        ..failUndo = true;
      await tester.pumpWidget(_app(controller, const Size(400, 800)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('browser-note-update-undo-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('browser-note-update-undo')));
      await tester.pumpAndSettle();
      expect(
        find.text('The browser action could not be completed'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('browser-note-update-undo-menu')),
        findsOneWidget,
      );

      controller.canUndo = false;
      await tester.enterText(
        find.byKey(const ValueKey('browser-search')),
        'front',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('browser-note-update-undo-menu')),
        findsNothing,
      );
    },
  );

  testWidgets('browser rows open the shared editor and refresh on return', (
    tester,
  ) async {
    final controller = _EditorController(_sample());
    await tester.pumpWidget(_app(controller, const Size(400, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    expect(find.text('Edit note'), findsOneWidget);
    expect(controller.resolvedRows, [const BrowserRowId(41)]);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Browse'), findsOneWidget);
    expect(controller.refreshCalls, 1);
  });

  testWidgets('Card Browser Add saves then preserves search and selection', (
    tester,
  ) async {
    final controller = _EditorController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('browser-add-note')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('browser-search')),
      'front',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    expect(controller.selectedRows, [const BrowserRowId(41)]);

    await tester.tap(find.byKey(const ValueKey('browser-add-note')));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(find.text('Add note'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('note-field-0')), 'new front');
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(controller.newNoteSaveCalls, 1);
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-0')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(controller.refreshCalls, 1);
    expect(controller.queries.last, 'front');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('browser-search')))
          .controller!
          .text,
      'front',
    );
    expect(controller.selectedRows, [const BrowserRowId(41)]);
  });

  testWidgets(
    'Card Browser preview action opens the collection preview route',
    (tester) async {
      final controller = _PreviewController(_sample());
      await tester.pumpWidget(_app(controller, const Size(800, 800)));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('browser-preview')));
      await tester.pumpAndSettle();

      expect(find.byType(CardBrowserPreviewScreen), findsOneWidget);
      expect(find.text('Question from active collection'), findsOneWidget);
      expect(controller.requestedSelection, [const BrowserRowId(41)]);
    },
  );

  testWidgets('preview action is available with no selected rows', (
    tester,
  ) async {
    final controller = _PreviewController(_sample());
    await tester.pumpWidget(_app(controller, const Size(800, 800)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('browser-preview')), findsOneWidget);
    expect(find.byTooltip('Preview'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('browser-preview')));
    await tester.pumpAndSettle();

    expect(find.byType(CardBrowserPreviewScreen), findsOneWidget);
    expect(find.text('Question from active collection'), findsOneWidget);
    expect(controller.requestedSelection, isEmpty);
  });

  testWidgets('legacy preview action stays hidden with no selection', (
    tester,
  ) async {
    final controller = _Controller(_sample());
    await tester.pumpWidget(_app(controller, const Size(800, 800)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('browser-preview')), findsNothing);

    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('browser-preview')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('browser-preview')));
    await tester.pumpAndSettle();
    expect(controller.previewed, [const BrowserRowId(41)]);
  });

  testWidgets('narrow row cards do not tint source row colors', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _Controller(
      CardBrowserSnapshot(
        columns: const [
          CardBrowserColumn(type: BrowserColumn.tags, label: 'Tags'),
        ],
        rows: [
          CardBrowserRow(
            id: const BrowserRowId(1),
            cells: const {'noteTags': 'marked'},
            color: CardBrowserRowColor.marked,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(controller, const Size(400, 800)));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('browser-row-1'));
    final card = tester.widget<Card>(
      find.descendant(of: row, matching: find.byType(Card)),
    );
    expect(card.color, const Color(0xffd9b2e9));
    expect(card.surfaceTintColor, Colors.transparent);
  });

  testWidgets(
    'narrow row option icons use the contrast-safe color for flag rows',
    (tester) async {
      const size = Size(400, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const flagColors = [
        CardBrowserRowColor.flagRed,
        CardBrowserRowColor.flagOrange,
        CardBrowserRowColor.flagGreen,
        CardBrowserRowColor.flagBlue,
        CardBrowserRowColor.flagPink,
        CardBrowserRowColor.flagTurquoise,
        CardBrowserRowColor.flagPurple,
      ];

      for (final brightness in [Brightness.light, Brightness.dark]) {
        final rows = [
          for (var i = 0; i < flagColors.length; i++)
            CardBrowserRow(
              id: BrowserRowId(i + 1),
              cells: {'noteTags': 'flag ${flagColors[i].name}'},
              color: flagColors[i],
            ),
        ];
        final theme = ThemeData(brightness: brightness);
        await tester.pumpWidget(
          _app(
            _Controller(
              CardBrowserSnapshot(
                columns: const [
                  CardBrowserColumn(type: BrowserColumn.tags, label: 'Tags'),
                ],
                rows: rows,
              ),
            ),
            size,
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < flagColors.length; i++) {
          final row = find.byKey(ValueKey('browser-row-${i + 1}'));
          final options = tester.widget<IconButton>(
            find.descendant(of: row, matching: find.byType(IconButton)),
          );
          final icon = options.icon as Icon;
          expect(
            icon.color,
            resolveCardBrowserRowForegroundColor(
              flagColors[i],
              Theme.of(tester.element(row)),
            ),
            reason: '${flagColors[i].name} on $brightness rows',
          );
        }
      }
    },
  );

  testWidgets(
    'row colors survive selection and errors use the theme background',
    (tester) async {
      final controller = _Controller(
        CardBrowserSnapshot(
          columns: const [
            CardBrowserColumn(type: BrowserColumn.tags, label: 'Tags'),
          ],
          rows: [
            CardBrowserRow(
              id: const BrowserRowId(1),
              cells: const {'noteTags': 'marked'},
              color: CardBrowserRowColor.marked,
            ),
            CardBrowserRow(
              id: const BrowserRowId(2),
              cells: const {'noteTags': 'error'},
              color: CardBrowserRowColor.flagRed,
              error: BrowserRowError.databaseCheckRequired,
            ),
          ],
        ),
      );
      await tester.pumpWidget(_app(controller, const Size(500, 800)));
      await tester.pumpAndSettle();

      final markedRow = find.byKey(const ValueKey('browser-row-1'));
      await tester.longPress(markedRow);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Ink>(
              find.descendant(of: markedRow, matching: find.byType(Ink)),
            )
            .any(
              (ink) =>
                  (ink.decoration as BoxDecoration).color ==
                  const Color(0xffd9b2e9),
            ),
        isTrue,
      );
      expect(
        tester
            .getSemantics(markedRow)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      final errorRow = find.byKey(const ValueKey('browser-row-2'));
      expect(
        tester
            .widgetList<Ink>(
              find.descendant(of: errorRow, matching: find.byType(Ink)),
            )
            .any(
              (ink) =>
                  (ink.decoration as BoxDecoration).color ==
                  const Color(0xffffffff),
            ),
        isTrue,
      );
      expect(
        tester
            .getSemantics(errorRow)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
    },
  );

  testWidgets(
    'error rows show the source message and unchecked selection state',
    (tester) async {
      final controller = _Controller(
        CardBrowserSnapshot(
          columns: const [
            CardBrowserColumn(type: BrowserColumn.tags, label: 'Tags'),
          ],
          rows: [
            CardBrowserRow(
              id: const BrowserRowId(7),
              cells: const {
                'noteTags':
                    'Please use the Check Database action, then try again.',
              },
              color: CardBrowserRowColor.unknown,
              error: BrowserRowError.databaseCheckRequired,
            ),
          ],
        ),
      );
      await tester.pumpWidget(_app(controller, const Size(500, 800)));
      await tester.pumpAndSettle();

      final message = find.text(
        'Please use the Check Database action, then try again.',
      );
      expect(message, findsOneWidget);
      expect(
        tester.widget<Text>(message).style?.decoration,
        TextDecoration.lineThrough,
      );
      final semantics = tester
          .getSemantics(find.byKey(const ValueKey('browser-row-7')))
          .getSemanticsData();
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isSelected, Tristate.isFalse);
      await tester.longPress(find.byKey(const ValueKey('browser-row-7')));
      expect(controller.selectedRows, [const BrowserRowId(7)]);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('browser-row-7')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      await tester.tap(message);
      await tester.pumpAndSettle();
      expect(controller.selectedRows, isEmpty);
      expect(controller.selectionUpdates.last, isEmpty);
    },
  );

  testWidgets('row font, RTL, and elision metadata do not alter cell text', (
    tester,
  ) async {
    final row = CardBrowserRow(
      id: const BrowserRowId(1),
      cells: const {'deck': 'Default Deck'},
      fontName: 'Custom Browser Font',
      fontSize: 24,
      rtlCells: const {'deck': true},
      elideModes: const {'deck': CardBrowserElideMode.middle},
    );
    await tester.pumpWidget(
      _app(
        _Controller(
          CardBrowserSnapshot(
            columns: const [
              CardBrowserColumn(type: BrowserColumn.deck, label: 'Deck'),
            ],
            rows: [row],
          ),
        ),
        const Size(500, 800),
      ),
    );
    await tester.pumpAndSettle();

    final cell = tester.widget<Text>(find.text('Default Deck'));
    expect(
      cell.style?.color,
      Theme.of(tester.element(find.text('Default Deck'))).colorScheme.onSurface,
    );
    expect(cell.style?.fontFamily, isNull);
    expect(cell.style?.fontSize, isNull);
    expect(cell.textDirection, isNull);
    expect(cell.overflow, TextOverflow.ellipsis);
    expect(cell.maxLines, isNot(1));
  });

  testWidgets('mode switch clears selection and publishes the returned mode', (
    tester,
  ) async {
    final controller = _Controller(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes').last);
    await tester.pumpAndSettle();

    expect(controller.modeChanges, [BrowserColumnMode.notes]);
    expect(controller.snapshot.mode, BrowserColumnMode.notes);
    expect(controller.selectionUpdates.last, isEmpty);
  });

  testWidgets('failed mode change refreshes invalidated undo availability', (
    tester,
  ) async {
    final controller = _UndoModeController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('browser-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('browser-note-update-undo-menu')),
      findsNothing,
    );
  });

  testWidgets(
    'renders dynamic columns in order and preserves row selection semantics',
    (tester) async {
      final controller = _Controller(_sample());
      await tester.pumpWidget(_app(controller, const Size(1000, 800)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('browser-heading-noteTags')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('browser-heading-question')),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('browser-heading-noteTags')))
            .dx,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('browser-heading-question')),
              )
              .dx,
        ),
      );
      expect(find.text('biology'), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
      await tester.pumpAndSettle();
      expect(controller.selectedRows, [const BrowserRowId(41)]);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('browser-row-41')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    },
  );

  testWidgets('saved search can be applied without submitting or submitted', (
    tester,
  ) async {
    final controller = _Controller(
      _sample(),
    )..savedSearches = [const BrowserSavedSearch(name: 'Due', query: 'is:due')];
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-saved-searches')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('browser-saved-search-apply-Due')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.queries, isEmpty);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('browser-search')))
          .controller!
          .text,
      'is:due ',
    );

    await tester.tap(find.byKey(const ValueKey('browser-saved-searches')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('browser-saved-search-submit-Due')),
    );
    await tester.pumpAndSettle();
    expect(controller.queries, ['is:due']);
  });

  testWidgets(
    'search history restores structured requests and supports edit, removal, expansion, and clear',
    (tester) async {
      final controller = _Controller(_sample())
        ..searchHistory = [
          for (var index = 0; index < 6; index++)
            BrowserSearchHistoryEntry(
              query: 'tag:history$index',
              tags: index == 0 ? const ['biology'] : const [],
            ),
        ];
      await tester.pumpWidget(_app(controller, const Size(500, 800)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('browser-search')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('browser-history-entry-4')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('browser-history-entry-5')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-history-toggle')),
      );
      await tester.tap(find.byKey(const ValueKey('browser-history-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('browser-history-entry-5')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-history-edit-0')),
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('browser-history-edit-0')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('browser-history-edit-0')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('browser-search')))
            .controller!
            .text,
        'tag:history0',
      );
      expect(controller.submittedRequests, isEmpty);

      await tester.tap(find.byKey(const ValueKey('browser-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('browser-history-remove-1')));
      await tester.pumpAndSettle();
      expect(controller.searchHistory, hasLength(5));

      await tester.tap(find.byKey(const ValueKey('browser-history-entry-0')));
      await tester.pumpAndSettle();
      expect(controller.submittedRequests, hasLength(1));
      expect(controller.submittedRequests.single.query, 'tag:history0');
      expect(controller.submittedRequests.single.filters.tags, ['biology']);

      await tester.tap(find.byKey(const ValueKey('browser-search')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-history-clear')),
      );
      await tester.tap(find.byKey(const ValueKey('browser-history-clear')));
      await tester.pumpAndSettle();
      expect(controller.searchHistory, isEmpty);

      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-search-filters')),
      );
      await tester.tap(find.byKey(const ValueKey('browser-search-filters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-filter-note-type-2')),
      );
      await tester.tap(
        find.byKey(const ValueKey('browser-filter-note-type-2')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-filter-tag-cell')),
      );
      await tester.tap(find.byKey(const ValueKey('browser-filter-tag-cell')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-filter-flag-1')),
      );
      await tester.tap(find.byKey(const ValueKey('browser-filter-flag-1')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('browser-filter-card-state-4')),
      );
      await tester.tap(
        find.byKey(const ValueKey('browser-filter-card-state-4')),
      );
      await tester.tap(find.byKey(const ValueKey('browser-filter-apply')));
      await tester.pumpAndSettle();
      final filteredRequest = controller.submittedRequests.last;
      expect(filteredRequest.filters.tags, ['biology', 'cell']);
      expect(filteredRequest.filters.decks, isEmpty);
      expect(
        filteredRequest.filters.noteTypes.map((noteType) => noteType.name),
        ['Basic'],
      );
      expect(filteredRequest.filters.flags, [1]);
      expect(filteredRequest.filters.cardStateCodes, [4]);
    },
  );

  testWidgets('history rows distinguish structured filter variants', (
    tester,
  ) async {
    final controller = _Controller(_sample())
      ..searchHistory = [
        const BrowserSearchHistoryEntry(query: 'tag:biology', tags: ['cell']),
        const BrowserSearchHistoryEntry(
          query: 'tag:biology',
          tags: ['genetics'],
        ),
      ]
      ..historyDisplayItems = [
        (searchString: 'tag:biology tag:cell', includesStructuredFilters: true),
        (
          searchString: 'tag:biology tag:genetics',
          includesStructuredFilters: true,
        ),
      ];
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-search')));
    await tester.pumpAndSettle();

    expect(find.text('tag:biology tag:cell'), findsOneWidget);
    expect(find.text('tag:biology tag:genetics'), findsOneWidget);
    expect(find.text('Tags: cell'), findsNothing);
    expect(find.text('Tags: genetics'), findsNothing);
  });

  testWidgets('history rows use the host canonical display strings', (
    tester,
  ) async {
    final controller = _Controller(_sample())
      ..searchHistory = [
        const BrowserSearchHistoryEntry(query: 'tag:query-only'),
        const BrowserSearchHistoryEntry(query: '', tags: ['cell']),
      ]
      ..historyDisplayItems = [
        (searchString: 'tag:query-only', includesStructuredFilters: false),
        (searchString: 'tag:cell', includesStructuredFilters: true),
      ];
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-search')));
    await tester.pumpAndSettle();

    expect(find.text('tag:query-only'), findsOneWidget);
    expect(find.text('tag:cell'), findsOneWidget);
    expect(find.text('Filtered search'), findsNothing);
    expect(find.text('Tags: cell'), findsNothing);
    expect(
      find.byKey(const ValueKey('browser-history-edit-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('browser-history-remove-1')),
      findsOneWidget,
    );
  });

  testWidgets('saved-search manager deletes an entry and shows empty state', (
    tester,
  ) async {
    final controller = _Controller(
      _sample(),
    )..savedSearches = [const BrowserSavedSearch(name: 'Due', query: 'is:due')];
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-saved-searches')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('browser-saved-search-delete-Due')),
    );
    await tester.pumpAndSettle();

    expect(controller.savedSearches, isEmpty);
    expect(find.text('No saved searches'), findsOneWidget);
  });

  testWidgets('saved-search storage failure uses the browser error state', (
    tester,
  ) async {
    final controller = _Controller(_sample())
      ..savedSearchLoadError = StateError('config unavailable');
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-saved-searches')));
    await tester.pumpAndSettle();

    expect(
      find.text('The browser action could not be completed'),
      findsOneWidget,
    );
  });

  testWidgets('renders BigInt row IDs without JavaScript narrowing', (
    tester,
  ) async {
    final wideId = BigInt.parse('9007199254740993');
    final controller = _Controller(
      CardBrowserSnapshot(
        columns: const [],
        rows: [
          CardBrowserRow(id: BrowserRowId.bigInt(wideId), cells: const {}),
        ],
      ),
    );
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('browser-row-9007199254740993')),
      findsOneWidget,
    );
  });

  testWidgets('saving a non-empty search stores its query with a name', (
    tester,
  ) async {
    final controller = _Controller(_sample());
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('browser-search')),
      '  tag:biology  ',
    );
    await tester.tap(find.byKey(const ValueKey('browser-save-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('browser-saved-search-name')),
      'Biology',
    );
    await tester.tap(
      find.byKey(const ValueKey('browser-saved-search-confirm')),
    );
    await tester.pumpAndSettle();

    expect(controller.savedSearches, [
      const BrowserSavedSearch(name: 'Biology', query: 'tag:biology'),
    ]);
  });

  testWidgets('search exposes searching, empty, and failure states', (
    tester,
  ) async {
    final controller = _Controller(_sample())
      ..loadError = StateError('initial unavailable')
      ..searchCompleter = Completer<CardBrowserSnapshot>();
    await tester.pumpWidget(_app(controller, const Size(500, 800)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('browser-search')),
      'is:due',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(controller.queries, ['is:due']);
    expect(
      find.byKey(const ValueKey('browser-search-progress')),
      findsOneWidget,
    );
    controller.searchCompleter!.complete(
      CardBrowserSnapshot(columns: [], rows: []),
    );
    await tester.pumpAndSettle();
    expect(find.text('No cards found'), findsOneWidget);

    controller.searchError = StateError('unavailable');
    await tester.enterText(
      find.byKey(const ValueKey('browser-search')),
      'bad query',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Could not load cards'), findsOneWidget);
    expect(find.byKey(const ValueKey('browser-search-retry')), findsOneWidget);
  });

  testWidgets('column options cannot remove the last active column', (
    tester,
  ) async {
    final controller = _Controller(
      CardBrowserSnapshot(
        columns: const [
          CardBrowserColumn(type: BrowserColumn.deck, label: 'Deck'),
        ],
        rows: [
          CardBrowserRow(id: const BrowserRowId(5), cells: {'deck': 'Default'}),
        ],
      ),
    );
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-heading-deck')));
    await tester.pumpAndSettle();
    final remove = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Remove column'),
        matching: find.byType(ListTile),
      ),
    );
    expect(remove.enabled, isFalse);
  });

  testWidgets(
    'column manager and options stay available on narrow empty results',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _Controller(
        CardBrowserSnapshot(
          columns: const [
            CardBrowserColumn(type: BrowserColumn.deck, label: 'Deck'),
          ],
          rows: const [],
        ),
      );
      await tester.pumpWidget(_app(controller, const Size(360, 800)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('browser-manage-columns')));
      await tester.pumpAndSettle();
      expect(find.text('Manage columns'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('browser-column-options-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deck'));
      await tester.pumpAndSettle();
      expect(find.text('Remove column'), findsOneWidget);
      await tester.tap(find.text('Manage columns'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _app(
          _Controller(
            CardBrowserSnapshot(
              columns: const [
                CardBrowserColumn(type: BrowserColumn.deck, label: 'Deck'),
              ],
              rows: [
                CardBrowserRow(
                  id: const BrowserRowId(3),
                  cells: {'deck': 'Default'},
                ),
              ],
            ),
          ),
          const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('browser-column-options-deck')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove column'), findsOneWidget);
    },
  );

  testWidgets('manage columns blocks empty and applies edited order', (
    tester,
  ) async {
    final controller = _Controller(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(
      find.byKey(const ValueKey('browser-heading-noteTags')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-column-noteTags')));
    await tester.tap(find.byKey(const ValueKey('browser-column-question')));
    await tester.pumpAndSettle();
    final apply = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Apply'),
    );
    expect(apply.onPressed, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.longPress(
      find.byKey(const ValueKey('browser-heading-noteTags')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move up').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(controller.savedColumns, [
      BrowserColumn.question,
      BrowserColumn.tags,
    ]);
  });

  testWidgets('sort, preview, edit, and bulk actions use injected callbacks', (
    tester,
  ) async {
    final controller = _Controller(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browser-heading-question')));
    await tester.pumpAndSettle();
    expect(find.text('Remove column'), findsOneWidget);
    await tester.tap(find.text('Remove column'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('browser-heading-question')),
    );
    await tester.longPress(
      find.byKey(const ValueKey('browser-heading-question')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage columns'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-sort-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags').last);
    await tester.pumpAndSettle();
    expect(controller.sortedColumns, [BrowserColumn.tags]);

    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    controller.sortCompleter = Completer<CardBrowserSnapshot>();
    await tester.tap(find.byKey(const ValueKey('browser-sort-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags').last);
    await tester.pump();
    controller.searchResult = CardBrowserSnapshot(
      columns: _sample().columns,
      rows: [
        CardBrowserRow(
          id: const BrowserRowId(99),
          cells: {'noteTags': 'recent', 'question': 'Newest result'},
        ),
      ],
    );
    await tester.enterText(find.byKey(const ValueKey('browser-search')), 'new');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('browser-row-99')), findsOneWidget);
    controller.sortCompleter!.complete(_sample());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('browser-row-99')), findsOneWidget);
    expect(find.byKey(const ValueKey('browser-row-41')), findsNothing);

    expect(controller.previewed, [const BrowserRowId(41)]);
    expect(controller.edited, [const BrowserRowId(41)]);
    expect(controller.bulkActions, hasLength(1));
    expect(controller.bulkActions.single.$1, CardBrowserBulkAction.suspend);
    expect(controller.bulkActions.single.$2, [const BrowserRowId(41)]);
  });

  testWidgets(
    'sort menu labels hidden columns and stays available when empty',
    (tester) async {
      final controller = _Controller(
        CardBrowserSnapshot(columns: const [], rows: const []),
      );
      await tester.pumpWidget(_app(controller, const Size(1000, 800)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('browser-sort-menu')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('browser-sort-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Sort field'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      await tester.tap(find.text('Sort field'));
      await tester.pumpAndSettle();
      expect(controller.sortedColumns, [BrowserColumn.sortField]);
    },
  );

  testWidgets('successful bulk operation exposes collection undo', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    expect(find.text('suspend cards completed'), findsOneWidget);
    expect(find.text('Undo suspend cards'), findsOneWidget);
    await tester.tap(find.text('Undo suspend cards'));
    await tester.pumpAndSettle();
    expect(controller.undoCalls, 1);
    expect(find.text('suspend cards undone'), findsOneWidget);
    expect(find.text('Redo suspend cards'), findsOneWidget);
    await tester.tap(find.text('Redo suspend cards'));
    await tester.pumpAndSettle();
    expect(controller.redoCalls, 1);
  });

  testWidgets('redo invalidation alone does not offer an older undo', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample())
      ..canUndo = true
      ..canRedo = true
      ..invalidateRedoWithoutEntry = true;
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(controller.canUndoCollectionOperation, isTrue);
    expect(controller.collectionUndoHasEntryAtCurrentGeneration, isFalse);
  });

  testWidgets('custom undo labels keep their name in localized feedback', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample())
      ..operationLabel = 'Review batch'
      ..customUndo = true;
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    expect(find.text('Custom: suspend cards completed'), findsNothing);
    expect(find.text('Custom: Review batch completed'), findsOneWidget);
    expect(find.text('Undo Custom: Review batch'), findsOneWidget);
  });

  testWidgets('unknown undo labels use localized generic feedback', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample())
      ..operationLabel = 'host custom operation';
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    expect(find.text('collection action completed'), findsOneWidget);
    expect(find.text('Undo collection action'), findsOneWidget);
    expect(find.text('host custom operation'), findsNothing);
  });

  testWidgets('an older bulk undo snackbar cannot undo a newer operation', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-bury')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SnackBarAction).first);
    await tester.pumpAndSettle();

    expect(controller.undoCalls, 0);
  });

  testWidgets('failed bulk undo leaves a reachable retry action', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    controller.failUndo = true;
    await tester.tap(find.text('Undo suspend cards'));
    await tester.pumpAndSettle();
    expect(
      find.text('The browser action could not be completed'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo suspend cards'), findsOneWidget);
  });

  testWidgets('failed bulk redo leaves a reachable retry action', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo suspend cards'));
    await tester.pumpAndSettle();

    controller.failRedo = true;
    await tester.tap(find.text('Redo suspend cards'));
    await tester.pumpAndSettle();
    expect(
      find.text('The browser action could not be completed'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Redo suspend cards'), findsOneWidget);
  });

  testWidgets('post-commit undo failure refreshes collection rows', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    final searchesBeforeUndo = controller.queries.length;
    controller.failUndoAfterCommit = true;
    await tester.tap(find.text('Undo suspend cards'));
    await tester.pumpAndSettle();

    expect(controller.queries, hasLength(searchesBeforeUndo + 1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Redo suspend cards'), findsOneWidget);
  });

  testWidgets('post-commit redo failure refreshes collection rows', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample());
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo suspend cards'));
    await tester.pumpAndSettle();

    final searchesBeforeRedo = controller.queries.length;
    controller.failRedoAfterCommit = true;
    await tester.tap(find.text('Redo suspend cards'));
    await tester.pumpAndSettle();

    expect(controller.queries, hasLength(searchesBeforeRedo + 1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo suspend cards'), findsOneWidget);
  });

  testWidgets('post-commit error still leaves the undo snackbar reachable', (
    tester,
  ) async {
    final controller = _UndoBulkController(_sample())..failAfterCommit = true;
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-suspend')));
    await tester.pumpAndSettle();

    expect(
      find.text('The browser action could not be completed'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo suspend cards'), findsOneWidget);
    await tester.tap(find.text('Undo suspend cards'));
    await tester.pumpAndSettle();
    expect(controller.undoCalls, 1);
  });

  testWidgets('sort menu preserves caller-projected active labels', (
    tester,
  ) async {
    final controller = _Controller(
      CardBrowserSnapshot(
        columns: const [
          CardBrowserColumn(type: BrowserColumn.tags, label: 'Custom tags'),
        ],
        rows: const [],
      ),
    );
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-sort-menu')));
    await tester.pumpAndSettle();

    expect(find.text('Custom tags'), findsOneWidget);
  });

  testWidgets('bulk delete refreshes rows and clears successful selection', (
    tester,
  ) async {
    final controller = _Controller(_sample())
      ..searchResult = CardBrowserSnapshot(
        columns: _sample().columns,
        rows: [
          CardBrowserRow(
            id: const BrowserRowId(42),
            cells: {'noteTags': 'chemistry', 'question': 'What is an atom?'},
          ),
        ],
      );
    await tester.pumpWidget(_app(controller, const Size(1000, 800)));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-delete')));
    await tester.pumpAndSettle();

    expect(controller.bulkActions.single.$1, CardBrowserBulkAction.delete);
    expect(controller.bulkActions.single.$2, [const BrowserRowId(41)]);
    expect(controller.queries, ['']);
    expect(find.byKey(const ValueKey('browser-row-41')), findsNothing);
    expect(find.byKey(const ValueKey('browser-row-42')), findsOneWidget);
    expect(controller.selectedRows, isEmpty);
    expect(find.byKey(const ValueKey('browser-preview')), findsNothing);
  });

  testWidgets('controller replacement clears selection before new actions', (
    tester,
  ) async {
    final previousController = _Controller(_sample());
    const size = Size(1000, 800);
    await tester.pumpWidget(_app(previousController, size));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('browser-search')),
      'is:due',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('browser-row-41')));
    await tester.pumpAndSettle();
    expect(previousController.selectedRows, [const BrowserRowId(41)]);

    final currentController = _Controller(
      CardBrowserSnapshot(
        columns: _sample().columns,
        rows: [
          CardBrowserRow(
            id: const BrowserRowId(99),
            cells: {'noteTags': 'recent', 'question': 'Newest result'},
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(currentController, size));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('browser-search')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(currentController.selectionUpdates, [<BrowserRowId>[]]);
    expect(find.byKey(const ValueKey('browser-preview')), findsNothing);

    await tester.longPress(find.byKey(const ValueKey('browser-row-99')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for selected cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('browser-bulk-delete')));
    await tester.pumpAndSettle();
    expect(currentController.bulkActions.single.$2, [const BrowserRowId(99)]);
  });

  testWidgets('wide and narrow layouts fit the available viewport', (
    tester,
  ) async {
    for (final size in [const Size(360, 780), const Size(1200, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(_Controller(_sample()), size));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(
          ValueKey(
            size.width < 700 ? 'browser-layout-narrow' : 'browser-layout-wide',
          ),
        ),
        findsOneWidget,
      );
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('wide tables keep many columns readable with horizontal scroll', (
    tester,
  ) async {
    const size = Size(1200, 800);
    final columns = BrowserColumn.values
        .map((type) => CardBrowserColumn(type: type, label: type.key))
        .toList();
    await tester.pumpWidget(
      _app(
        _Controller(
          CardBrowserSnapshot(
            columns: columns,
            rows: [
              CardBrowserRow(
                id: const BrowserRowId(1),
                cells: {
                  for (final type in BrowserColumn.values) type.key: type.key,
                },
              ),
            ],
          ),
        ),
        size,
      ),
    );
    await tester.pumpAndSettle();

    final lastHeading = find.byKey(
      const ValueKey('browser-heading-originalPosition'),
    );
    expect(tester.getTopLeft(lastHeading).dx, greaterThan(size.width));

    final horizontalScroll = find.byKey(
      const ValueKey('browser-wide-horizontal-scroll'),
    );
    await tester.drag(horizontalScroll, const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(lastHeading).dx, lessThan(size.width));
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  _Controller controller,
  Size size, {
  ThemeData? theme,
  Int64? launchDeckId,
}) => MaterialApp(
  theme: theme,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: CardBrowserScreen(
      controller: controller,
      launchDeckId: launchDeckId,
    ),
  ),
);

CardBrowserSnapshot _sample() => CardBrowserSnapshot(
  columns: [
    CardBrowserColumn(type: BrowserColumn.tags, label: 'Tags'),
    CardBrowserColumn(type: BrowserColumn.question, label: 'Question'),
  ],
  rows: [
    CardBrowserRow(
      id: const BrowserRowId(41),
      cells: {'noteTags': 'biology', 'question': 'What is a cell?'},
    ),
    CardBrowserRow(
      id: const BrowserRowId(42),
      cells: {'noteTags': 'chemistry', 'question': 'What is an atom?'},
    ),
  ],
);

class _Controller
    implements
        CardBrowserController,
        CardBrowserModeController,
        CardBrowserSearchRequestController,
        CardBrowserSearchHistoryController,
        CardBrowserSearchHistoryDisplayController,
        CardBrowserSearchFilterOptionsController {
  _Controller(this.snapshot);

  CardBrowserSnapshot snapshot;
  Completer<CardBrowserSnapshot>? searchCompleter;
  Completer<CardBrowserSnapshot>? sortCompleter;
  CardBrowserSnapshot? searchResult;
  Object? searchError;
  Object? loadError;
  int loadCalls = 0;
  final queries = <String>[];
  final sortedColumns = <BrowserColumn>[];
  final openedColumnOptions = <BrowserColumn>[];
  List<BrowserColumn>? savedColumns;
  int manageColumnsCount = 0;
  final selectedRows = <BrowserRowId>[];
  final selectionUpdates = <List<BrowserRowId>>[];
  final previewed = <BrowserRowId>[];
  final edited = <BrowserRowId>[];
  final bulkActions = <(CardBrowserBulkAction, List<BrowserRowId>)>[];
  final modeChanges = <BrowserColumnMode>[];
  List<BrowserSavedSearch> savedSearches = [];
  Object? savedSearchLoadError;
  List<BrowserSearchHistoryEntry> searchHistory = [];
  List<CardBrowserSearchHistoryDisplayItem> historyDisplayItems = [];
  final submittedRequests = <BrowserSearchRequest>[];

  @override
  Future<CardBrowserSnapshot> load() async {
    loadCalls++;
    final error = loadError;
    if (error != null) {
      loadError = null;
      throw error;
    }
    return snapshot;
  }

  @override
  Future<CardBrowserSnapshot> search(String query) {
    queries.add(query);
    final error = searchError;
    if (error != null) return Future.error(error);
    return searchCompleter?.future ?? Future.value(searchResult ?? snapshot);
  }

  @override
  Future<CardBrowserSnapshot> searchRequest(BrowserSearchRequest request) {
    submittedRequests.add(request);
    queries.add(request.query);
    final error = searchError;
    if (error != null) return Future.error(error);
    return searchCompleter?.future ?? Future.value(searchResult ?? snapshot);
  }

  @override
  Future<List<BrowserSearchHistoryEntry>> loadSearchHistory() async =>
      List.of(searchHistory);

  @override
  Future<List<CardBrowserSearchHistoryDisplayItem>>
  loadSearchHistoryDisplayItems(
    List<BrowserSearchHistoryEntry> entries,
  ) async => historyDisplayItems.isEmpty
      ? [
          for (final entry in entries)
            (
              searchString: entry.query.isEmpty ? null : entry.query,
              includesStructuredFilters: false,
            ),
        ]
      : List.of(historyDisplayItems);

  @override
  Future<BrowserSearchRequest> restoreSearchHistoryEntry(
    BrowserSearchHistoryEntry entry,
  ) async => BrowserSearchRequest(
    query: entry.query,
    filters: BrowserSearchFilters(tags: entry.tags),
  );

  @override
  Future<void> removeSearchHistoryEntry(BrowserSearchHistoryEntry entry) async {
    searchHistory.remove(entry);
  }

  @override
  Future<void> clearSearchHistory() async => searchHistory.clear();

  @override
  Future<CardBrowserSearchFilterOptions> loadSearchFilterOptions() async =>
      CardBrowserSearchFilterOptions(
        decks: [BrowserDeckNameId(name: 'Default', id: BigInt.one)],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: BigInt.from(2))],
        tags: const ['biology', 'cell'],
      );

  @override
  Future<List<BrowserSavedSearch>> loadSavedSearches() async {
    final error = savedSearchLoadError;
    if (error != null) throw error;
    return List.of(savedSearches);
  }

  @override
  Future<(bool, List<BrowserSavedSearch>)> addSavedSearch(
    BrowserSavedSearch savedSearch,
  ) async {
    if (savedSearches.any((saved) => saved.name == savedSearch.name)) {
      return (false, List.of(savedSearches));
    }
    final normalized = savedSearch.normalize();
    savedSearches = [...savedSearches, normalized]
      ..sort((left, right) => left.name.compareTo(right.name));
    return (true, List.of(savedSearches));
  }

  @override
  Future<(bool, List<BrowserSavedSearch>)> deleteSavedSearch(
    String name,
  ) async {
    final updated = savedSearches.where((saved) => saved.name != name).toList();
    if (updated.length == savedSearches.length) return (false, updated);
    savedSearches = updated;
    return (true, List.of(savedSearches));
  }

  @override
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType) async {
    sortedColumns.add(
      BrowserColumn.fromColumnKey(
        (sortType as BrowserSortCollectionOrdering).key,
      ),
    );
    final completer = sortCompleter;
    if (completer != null) return completer.future;
    return CardBrowserSnapshot(
      columns: snapshot.columns,
      rows: snapshot.rows,
      sortType: sortType,
    );
  }

  @override
  Future<CardBrowserSnapshot> updateMode(BrowserColumnMode mode) async {
    modeChanges.add(mode);
    snapshot = CardBrowserSnapshot(
      columns: snapshot.columns,
      rows: snapshot.rows,
      sortType: snapshot.sortType,
      mode: mode,
    );
    return snapshot;
  }

  @override
  Future<void> openColumnOptions(BrowserColumn column) async =>
      openedColumnOptions.add(column);

  @override
  Future<void> manageColumns() async => manageColumnsCount++;

  @override
  Future<void> saveColumns(List<BrowserColumn> columns) async {
    savedColumns = List.of(columns);
  }

  @override
  Future<void> updateSelection(List<BrowserRowId> rows) async {
    selectionUpdates.add(List.of(rows));
    selectedRows
      ..clear()
      ..addAll(rows);
  }

  @override
  Future<void> preview(BrowserRowId rowId) async => previewed.add(rowId);

  @override
  Future<void> edit(BrowserRowId rowId) async => edited.add(rowId);

  @override
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> rows,
  ) async {
    bulkActions.add((action, List.of(rows)));
  }
}

final class _PreviewController extends _Controller
    implements CardBrowserPreviewController {
  _PreviewController(super.snapshot);

  List<BrowserRowId> requestedSelection = const [];

  @override
  Future<CardBrowserPreviewSession> loadPreview({
    required List<BrowserRowId> selectedRows,
  }) async {
    requestedSelection = selectedRows;
    return CardBrowserPreviewSession(
      cards: [
        CardBrowserPreviewCard(
          id: BigInt.from(snapshot.rows.first.id.value),
          questionHtml: '<p>Question from active collection</p>',
          answerHtml: '<p>Answer from active collection</p>',
        ),
      ],
      currentIndex: 0,
    );
  }
}

final class _UndoBulkController extends _Controller
    implements CardBrowserCollectionUndoController {
  _UndoBulkController(super.snapshot);

  int generation = 0;
  String operationLabel = 'suspendCards';
  int undoCalls = 0;
  int redoCalls = 0;
  bool canUndo = false;
  bool canRedo = false;
  bool hasCurrentEntry = false;
  bool customUndo = false;
  bool customRedo = false;
  bool failAfterCommit = false;
  bool failUndo = false;
  bool failRedo = false;
  bool failUndoAfterCommit = false;
  bool failRedoAfterCommit = false;
  bool invalidateRedoWithoutEntry = false;

  @override
  bool get canUndoCollectionOperation => canUndo;

  @override
  bool get canRedoCollectionOperation => canRedo;

  @override
  String? get collectionUndoLabel => canUndo ? operationLabel : null;

  @override
  String? get collectionRedoLabel => canRedo ? operationLabel : null;

  @override
  int get collectionUndoGeneration => generation;

  @override
  bool get collectionUndoHasEntryAtCurrentGeneration => hasCurrentEntry;

  @override
  bool get collectionUndoIsCustom => customUndo;

  @override
  bool get collectionRedoIsCustom => customRedo;

  @override
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> rows,
  ) async {
    if (invalidateRedoWithoutEntry) {
      canRedo = false;
      hasCurrentEntry = false;
      generation++;
      return;
    }
    await super.performBulkAction(action, rows);
    canUndo = true;
    hasCurrentEntry = true;
    generation++;
    if (failAfterCommit) throw StateError('flush failure after commit');
  }

  @override
  Future<void> undoLastCollectionOperation() async {
    if (failUndo) throw StateError('injected undo failure');
    undoCalls++;
    canUndo = false;
    hasCurrentEntry = false;
    canRedo = true;
    generation++;
    if (failUndoAfterCommit) {
      throw StateError('injected flush failure after undo commit');
    }
  }

  @override
  Future<void> redoLastCollectionOperation() async {
    if (failRedo) throw StateError('injected redo failure');
    redoCalls++;
    canUndo = true;
    hasCurrentEntry = true;
    canRedo = false;
    generation++;
    if (failRedoAfterCommit) {
      throw StateError('injected flush failure after redo commit');
    }
  }
}

class _EditorController extends _Controller
    implements
        CardBrowserNewNoteEditorController,
        CardBrowserNoteUpdateUndoController {
  _EditorController(super.snapshot);

  final resolvedRows = <BrowserRowId>[];
  int refreshCalls = 0;
  int newNoteSaveCalls = 0;
  bool canUndo = false;
  bool collectionClosed = false;
  bool invalidateUndoOnSort = false;
  bool failUndo = false;
  bool pendingUndoActive = false;
  Completer<void>? pendingUndo;
  int undoCalls = 0;

  @override
  bool get canUndoNoteUpdate {
    if (collectionClosed) throw StateError('collection closed');
    return canUndo;
  }

  @override
  bool get noteUpdateUndoPending => pendingUndoActive;

  @override
  Future<Int64> resolveNoteIdForRow(BrowserRowId rowId) async {
    resolvedRows.add(rowId);
    return Int64.parseInt(rowId.bigValue.toString());
  }

  @override
  Future<NoteEditorContent> loadNote(Int64 noteId) async =>
      NoteEditorContent(labels: const ['Front'], values: const ['front']);

  @override
  Future<NewNoteEditorDraft> loadNewNote() async => NewNoteEditorDraft(
    notetypeId: Int64.ONE,
    deckId: Int64.ONE,
    content: NoteEditorContent(labels: const ['Front'], values: const ['']),
  );

  @override
  Future<NewNoteEditorDraft> changeNewNoteType({
    required NewNoteEditorDraft draft,
    required Int64 notetypeId,
    required List<String> fields,
    required List<String> tags,
  }) => Future.error(UnimplementedError());

  @override
  Future<List<NewNoteEditorDeck>> loadSelectableDecks() async => [
    NewNoteEditorDeck(id: Int64.ONE, name: 'Default'),
  ];

  @override
  Future<NoteFieldsCheckResult> validateNewNote(
    Int64 notetypeId,
    List<String> fields,
  ) async => const NoteFieldsCheckSuccess();

  @override
  Future<int> saveNewNote({
    required NewNoteEditorDraft draft,
    required List<String> fields,
    required List<String> tags,
  }) async {
    newNoteSaveCalls++;
    return 1;
  }

  @override
  Future<void> saveNote(
    Int64 noteId,
    List<String> fields,
    List<String> tags,
  ) async {
    canUndo = true;
  }

  @override
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType) async {
    final result = await super.updateSort(sortType);
    if (invalidateUndoOnSort) canUndo = false;
    return result;
  }

  @override
  Future<CardBrowserSnapshot> refresh() async {
    refreshCalls++;
    return snapshot;
  }

  @override
  Future<void> undoLastNoteUpdate() async {
    undoCalls++;
    pendingUndoActive = true;
    try {
      if (failUndo) throw StateError('replay failed');
      await pendingUndo?.future;
      canUndo = false;
    } finally {
      pendingUndoActive = false;
    }
  }
}

final class _DeckSelectionController extends _Controller
    implements CardBrowserDeckSelectionController {
  _DeckSelectionController(super.snapshot);

  Int64? launchDeckId;
  Int64 selectedDeckId = Int64.ZERO;
  int initializeCalls = 0;
  final selectionCalls = <Int64?>[];

  @override
  Future<void> initializeBrowser({required Int64? launchDeckId}) async {
    initializeCalls++;
    this.launchDeckId = launchDeckId;
    selectedDeckId = launchDeckId ?? Int64.ONE;
  }

  @override
  Future<Int64?> loadSelectedBrowserDeck() async =>
      selectedDeckId == Int64.ZERO ? null : selectedDeckId;

  @override
  Future<String?> loadSelectedBrowserDeckName() async =>
      selectedDeckId == Int64.ZERO ? null : 'Wide deck';

  @override
  Future<CardBrowserSnapshot> selectBrowserDeck(Int64? deckId) async {
    selectionCalls.add(deckId);
    selectedDeckId = deckId ?? Int64.ZERO;
    return snapshot;
  }

  @override
  Future<CardBrowserSearchFilterOptions> loadSearchFilterOptions() async =>
      CardBrowserSearchFilterOptions(
        decks: [
          BrowserDeckNameId(
            name: 'Wide deck',
            id: BigInt.parse('9007199254740995'),
          ),
        ],
        noteTypes: const [],
        tags: const [],
      );
}

final class _UndoModeController extends _Controller
    implements CardBrowserNoteUpdateUndoController {
  _UndoModeController(super.snapshot);

  bool canUndo = true;

  @override
  bool get canUndoNoteUpdate => canUndo;

  @override
  bool get noteUpdateUndoPending => false;

  @override
  Future<void> undoLastNoteUpdate() async {
    canUndo = false;
  }

  @override
  Future<CardBrowserSnapshot> updateMode(BrowserColumnMode mode) async {
    canUndo = false;
    throw StateError('mode update failed after collection invalidation');
  }
}
