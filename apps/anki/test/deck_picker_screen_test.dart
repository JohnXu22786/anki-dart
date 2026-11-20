/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:anki_app/deck_picker_screen.dart';
import 'package:anki_app/deck_description_editor.dart';
import 'package:anki_app/deck_options_editor.dart';
import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/note_editor_screen.dart';
import 'package:anki_backend_models/anki_backend_models.dart'
    show normalizeDeckName;
import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'Deck Picker Add Card selects its deck and opens the shared editor',
    (tester) async {
      final editor = _FakeDeckPickerNewNotePort();
      final repository = _DeckRepository([
        DeckPickerDeck(
          id: 42,
          exactId: Int64(9007199254740995),
          name: 'Grammar',
        ),
      ])..editorPort = editor;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions for Grammar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add card'));
      await tester.pumpAndSettle();

      expect(repository.selected, [42]);
      expect(repository.selectedExact, [Int64(9007199254740995)]);
      expect(editor.loadCalls, 1);
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.text('Add note'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DeckPickerScreen), findsOneWidget);
      expect(repository.loadCalls, 2);
      expect(repository.actions, isEmpty);
    },
  );

  testWidgets('description editor loads, saves both fields, and refreshes', (
    tester,
  ) async {
    final deck = DeckPickerDeck(
      id: 8,
      exactId: Int64.parseInt('9007199254740995'),
      name: 'Languages::Spanish',
    );
    final repository = _DeckRepository([deck])
      ..description = 'Stored description'
      ..markdownDescription = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit deck description'));
    await tester.pumpAndSettle();

    expect(repository.descriptionLoads, [Int64.parseInt('9007199254740995')]);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('deck-description-input')),
          )
          .controller!
          .text,
      'Stored description',
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('deck-description-markdown')),
          )
          .value,
      isTrue,
    );
    await tester.enterText(
      find.byKey(const ValueKey('deck-description-input')),
      'Edited **description**',
    );
    await tester.tap(find.byKey(const ValueKey('deck-description-markdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.savedDescriptionIds, [
      Int64.parseInt('9007199254740995'),
    ]);
    expect(repository.description, 'Edited **description**');
    expect(repository.markdownDescription, isFalse);
    expect(repository.loadCalls, 2);
    expect(find.text('Deck description saved'), findsOneWidget);
  });

  testWidgets('Deck Options loads and saves daily limits for exact deck', (
    tester,
  ) async {
    final deck = DeckPickerDeck(
      id: 8,
      exactId: Int64.parseInt('9007199254740995'),
      name: 'Languages::Spanish',
    );
    final repository = _DeckRepository([deck]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deck options'));
    await tester.pumpAndSettle();

    expect(repository.dailyLimitLoads, [Int64.parseInt('9007199254740995')]);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('187'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('deck-new-limit')), '42');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('deck-new-limit')))
          .controller!
          .text,
      '42',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.dailyLimitSaves, [
      (Int64.parseInt('9007199254740995'), 42, 187),
    ]);
    expect(repository.loadCalls, 2);
    expect(find.text('Deck options saved'), findsOneWidget);
    expect(find.byType(DeckOptionsEditor), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckOptionsEditor), findsNothing);
  });

  testWidgets('filtered Deck Options stay on their separate action path', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 9, name: 'Filtered', filtered: true),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Filtered'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deck options'));
    await tester.pumpAndSettle();

    expect(repository.dailyLimitLoads, isEmpty);
    expect(repository.actions, [(DeckPickerAction.deckOptions, 9)]);
    expect(find.byType(DeckOptionsEditor), findsNothing);
  });

  testWidgets('description editor closes unchanged and confirms discard', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Languages::Spanish'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit deck description'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(DeckDescriptionEditor), findsNothing);

    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit deck description'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deck-description-input')),
      'Unsaved',
    );
    await tester.tap(find.text('Close').last);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckDescriptionEditor), findsNothing);
    expect(repository.savedDescriptionIds, isEmpty);
  });

  testWidgets('description load failure is visible', (tester) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Languages::Spanish'),
    ]);
    repository.failDescriptionLoad = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit deck description'));
    await tester.pumpAndSettle();
    expect(find.text('Deck action could not be completed'), findsOneWidget);
    expect(find.byType(DeckDescriptionEditor), findsNothing);
  });

  testWidgets('description save failure keeps the editor open', (tester) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Languages::Spanish'),
    ])..failDescriptionSave = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit deck description'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deck-description-input')),
      'Fails to save',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('deck-description-input')),
          )
          .controller!
          .text,
      'Fails to save',
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repository.savedDescriptionIds, [Int64(8)]);
    expect(find.text('Deck description could not be saved'), findsOneWidget);
    expect(find.byType(DeckDescriptionEditor), findsOneWidget);
  });
  testWidgets(
    'create subdeck uses the parent exact ID and ignores empty input',
    (tester) async {
      final parent = DeckPickerDeck(
        id: 8,
        exactId: Int64.parseInt('9007199254740995'),
        name: 'Languages',
      );
      final repository = _DeckRepository([parent]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions for Languages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create subdeck'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('subdeck-name')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Create'))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const ValueKey('subdeck-name')), '""');
      await tester.pumpAndSettle();
      expect(find.text('A deck with this name already exists'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Create'))
            .onPressed,
        isNull,
      );
      repository.failNextSubdeck = true;
      await tester.enterText(
        find.byKey(const ValueKey('subdeck-name')),
        'Spanish',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('Deck action could not be completed'), findsOneWidget);
      expect(repository.createdSubdecks, isEmpty);
      final reloadsAfterFailure = repository.loadCalls;

      await tester.tap(find.byTooltip('More actions for Languages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create subdeck'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('subdeck-name')),
        'Spanish',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(repository.createdSubdecks, [
        (Int64.parseInt('9007199254740995'), 'Spanish'),
      ]);
      expect(repository.loadCalls, greaterThan(reloadsAfterFailure));
      expect(repository.actions, isEmpty);
    },
  );

  testWidgets('delete uses the exact deck ID, progress, result and undo', (
    tester,
  ) async {
    final deck = DeckPickerDeck(
      id: 8,
      exactId: Int64.parseInt('9007199254740995'),
      name: 'Languages::Spanish',
      reviewCount: 12,
    );
    final repository = _DeckRepository([deck]);
    final deletion = Completer<DeckPickerDeletionResult>();
    repository.pendingDelete = deletion;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete deck'));
    await tester.pump();

    expect(find.text('Deleting deck…'), findsOneWidget);
    expect(repository.deletedExact, [Int64.parseInt('9007199254740995')]);
    expect(find.text('Are you sure?'), findsNothing);

    deletion.complete(
      const DeckPickerDeletionResult(
        deckName: 'Languages::Spanish',
        cardsDeleted: 12,
        collectionUndoGeneration: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spanish'), findsNothing);
    expect(repository.currentDeckId, 1);
    expect(
      find.text('Cards deleted from Languages::Spanish: 12'),
      findsOneWidget,
    );
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('Deck deletion undone'), findsOneWidget);
    expect(find.text('Redo'), findsOneWidget);
  });

  testWidgets('unbury uses the exact deck ID and offers undo and redo', (
    tester,
  ) async {
    final deck = DeckPickerDeck(
      id: 8,
      exactId: Int64.parseInt('9007199254740995'),
      name: 'Languages::Spanish',
      hasBuried: true,
    );
    final repository = _DeckRepository([deck]);
    final unbury = Completer<DeckPickerUnburyResult>();
    repository.pendingUnbury = unbury;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Spanish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unbury cards'));
    await tester.pump();

    expect(find.text('Unburying cards…'), findsOneWidget);
    expect(repository.unburiedExact, [Int64.parseInt('9007199254740995')]);
    unbury.complete(
      const DeckPickerUnburyResult(
        deckName: 'Languages::Spanish',
        cardsUnburied: 3,
        collectionUndoGeneration: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Cards unburied from Languages::Spanish: 3'),
      findsOneWidget,
    );
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repository.undoCalls, 1);
    expect(find.text('Deck unbury undone'), findsOneWidget);
    await tester.tap(find.text('Redo'));
    await tester.pumpAndSettle();
    expect(find.text('Deck unbury redone'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('unbury failure dismisses progress and reports an error', (
    tester,
  ) async {
    final deck = const DeckPickerDeck(id: 9, name: 'Buried', hasBuried: true);
    final repository = _DeckRepository([deck])..failUnbury = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Buried'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unbury cards'));
    await tester.pumpAndSettle();

    expect(find.text('Unburying cards…'), findsNothing);
    expect(find.text('Deck action could not be completed'), findsOneWidget);
    expect(repository.loadCalls, 2);
  });

  testWidgets('delete error dismisses progress, reports failure and reloads', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 9, name: 'Temporary'),
    ])..failDelete = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final loadsBeforeAction = repository.loadCalls;

    await tester.tap(find.byTooltip('More actions for Temporary'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete deck'));
    await tester.pumpAndSettle();

    expect(find.text('Deleting deck…'), findsNothing);
    expect(find.text('Deck action could not be completed'), findsOneWidget);
    expect(repository.loadCalls, loadsBeforeAction + 1);
    expect(find.text('Temporary'), findsOneWidget);
  });

  testWidgets('committed deletion with a flush warning still offers undo', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 10, name: 'Committed'),
    ]);
    final deletion = Completer<DeckPickerDeletionResult>();
    repository.pendingDelete = deletion;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Committed'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete deck'));
    await tester.pump();
    deletion.complete(
      const DeckPickerDeletionResult(
        deckName: 'Committed',
        cardsDeleted: 2,
        collectionUndoGeneration: 1,
        persistenceWarning: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cards deleted from Committed: 2'),
      findsOneWidget,
    );
    expect(find.textContaining('Storage could not be synced.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(repository.canUndoCollectionOperation, isTrue);
  });

  testWidgets('delete undo does not target a later collection operation', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 10, name: 'Committed'),
    ])..advanceUndoGenerationAfterDelete = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Committed'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete deck'));
    await tester.pumpAndSettle();

    expect(repository.collectionUndoGeneration, 2);
    expect(find.text('Undo'), findsNothing);
    expect(repository.undoCalls, 0);
  });

  testWidgets('A opens the shared editor without overriding the current deck', (
    tester,
  ) async {
    final editor = _FakeDeckPickerNewNotePort();
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 1, name: 'Current'),
    ])..editorPort = editor;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();

    expect(repository.currentDeckNewNoteRequests, 1);
    expect(repository.selected, isEmpty);
    expect(editor.loadCalls, 1);
    expect(find.byType(NoteEditorScreen), findsOneWidget);
  });

  testWidgets('A remains available to the Deck Picker search field', (
    tester,
  ) async {
    final repository = _DeckRepository([
      for (var id = 1; id <= 10; id++) DeckPickerDeck(id: id, name: 'Deck $id'),
    ])..editorPort = _FakeDeckPickerNewNotePort();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();

    expect(repository.currentDeckNewNoteRequests, 0);
    expect(find.byType(NoteEditorScreen), findsNothing);
  });

  testWidgets(
    'shows hierarchical names and counts and sends selected deck to study',
    (tester) async {
      final repository = _DeckRepository([
        const DeckPickerDeck(
          id: 1,
          name: 'Languages',
          newCount: 2,
          learningCount: 3,
          reviewCount: 4,
          children: [
            DeckPickerDeck(
              id: 2,
              name: 'Languages::Spanish',
              newCount: 1,
              learningCount: 0,
              reviewCount: 5,
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.text('Languages'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('deck-row-2')));
      await tester.pumpAndSettle();
      expect(repository.selected, [2]);
      await tester.tap(find.byKey(const ValueKey('deck-study-selected')));
      await tester.pump();
      expect(repository.studied, [2]);
    },
  );

  testWidgets('initially selects and can study the host current deck', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 1, name: 'First'),
      const DeckPickerDeck(id: 2, name: 'Current'),
    ])..currentDeckId = 2;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('deck-row-2')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('deck-study-selected')));
    await tester.pumpAndSettle();
    expect(repository.studied, [2]);
  });

  testWidgets(
    'narrow selected-deck study action does not overlap the add FAB',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(_DeckRepository([const DeckPickerDeck(id: 1, name: 'Biology')])),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deck-row-1')));
      await tester.pumpAndSettle();

      final studyRect = tester.getRect(
        find.byKey(const ValueKey('deck-study-selected')),
      );
      final addFabRect = tester.getRect(
        find.byKey(const ValueKey('deck-picker-add')),
      );
      expect(studyRect.overlaps(addFabRect), isFalse);
    },
  );

  testWidgets(
    'filtered deck flow submits entered options without interpreting them',
    (tester) async {
      final repository = _DeckRepository(const []);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deck-picker-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create filtered deck'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('filtered-deck-name')),
        'Review later',
      );
      await tester.enterText(
        find.byKey(const ValueKey('filtered-search-1')),
        'is:due',
      );
      await tester.enterText(
        find.byKey(const ValueKey('filtered-limit-1')),
        '35',
      );
      await tester.tap(
        find.byKey(const ValueKey('filtered-second-filter-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('filtered-search-2')),
        'tag:important',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('filtered-reschedule')),
      );
      await tester.tap(find.byKey(const ValueKey('filtered-reschedule')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('filtered-delay-again')),
        '20',
      );
      await tester.ensureVisible(find.text('Build'));
      await tester.tap(find.text('Build'));
      await tester.pumpAndSettle();

      expect(repository.filteredRequests, hasLength(1));
      expect(repository.filteredRequests.single.name, 'Review later');
      expect(repository.filteredRequests.single.search1, 'is:due');
      expect(repository.filteredRequests.single.limit1, '35');
      expect(repository.filteredRequests.single.search2, 'tag:important');
      expect(repository.filteredRequests.single.shouldReschedule, isFalse);
      expect(repository.filteredRequests.single.delayAgain, '20');
      expect(find.byKey(const ValueKey('deck-picker-add')), findsOneWidget);
    },
  );

  testWidgets('canceling filtered deck options closes the add menu', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_DeckRepository(const [])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-picker-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create filtered deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-picker-add')), findsOneWidget);
    expect(find.text('Create filtered deck'), findsNothing);
  });

  testWidgets('filtered deck form starts from host-projected options', (
    tester,
  ) async {
    final repository = _DeckRepository(const [])
      ..newFilteredDeckOptions = const FilteredDeckOptions(
        name: 'Suggested deck',
        title: 'Host filtered-deck title',
        shouldReschedule: false,
        allowEmpty: false,
        cardOptions: ['Host order', 'Host alternate order'],
        filter1State: SearchTermState(
          search: 'tag:biology',
          limit: '22',
          index: 3,
        ),
        isSecondFilterEnabled: true,
        filter2State: SearchTermState(search: 'is:due', limit: '8', index: 2),
        delayAgain: '12',
        delayHard: '34',
        delayGood: '56',
      )
      ..filteredOrderNumbers = [2, 3];
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-picker-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create filtered deck'));
    await tester.pumpAndSettle();

    expect(find.text('Host filtered-deck title'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('filtered-deck-name')))
          .controller
          ?.text,
      'Suggested deck',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('filtered-search-1')))
          .controller
          ?.text,
      'tag:biology',
    );
    expect(find.text('Host alternate order'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('filtered-order-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Host order').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Build'));
    await tester.tap(find.text('Build'));
    await tester.pumpAndSettle();

    final request = repository.filteredRequests.single;
    expect(request.order1, 2);
    expect(request.order2, 2);
    expect(request.shouldReschedule, isFalse);
    expect(request.allowEmpty, isFalse);
    expect(request.delayAgain, '12');
    expect(request.delayHard, '34');
    expect(request.delayGood, '56');
  });

  testWidgets(
    'loading, empty, unavailable and failed states are visible and retryable',
    (tester) async {
      final repository = _DeckRepository(const [])..pendingLoad = true;
      await tester.pumpWidget(_app(repository));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.completeLoad(const []);
      await tester.pumpAndSettle();
      expect(find.text('No decks yet'), findsOneWidget);

      repository.failLoad = true;
      await tester.tap(find.byTooltip('Refresh decks'));
      await tester.pump();
      repository.completeFailure();
      await tester.pumpAndSettle();
      expect(find.text('Decks could not be loaded'), findsOneWidget);
      repository.failLoad = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No decks yet'), findsOneWidget);

      await tester.pumpWidget(_app(const UnavailableDeckPickerRepository()));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Decks are unavailable until a collection service is connected.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('deck rows expose actions to assistive technology', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(
        id: 8,
        name: 'Biology',
        newCount: 1,
        learningCount: 2,
        reviewCount: 3,
      ),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('deck-row-8')),
    );
    expect(semantics.label, contains('Biology'));
    expect(find.byTooltip('More actions for Biology'), findsOneWidget);
    final actions = tester.getSemantics(
      find.byTooltip('More actions for Biology'),
    );
    expect(actions.getSemanticsData().tooltip, 'More actions for Biology');
    expect(actions.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('search uses source deck matching and keeps matching ancestors', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(
        id: 1,
        name: 'Languages',
        children: [DeckPickerDeck(id: 2, name: 'Languages::Spanish')],
      ),
      for (var id = 3; id < 12; id++) DeckPickerDeck(id: id, name: 'Topic $id'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Spanish');
    await tester.pumpAndSettle();
    expect(find.text('Languages'), findsOneWidget);
    expect(find.text('Spanish').first, findsOneWidget);
    expect(find.text('Topic 3'), findsNothing);
    expect(find.byTooltip('Collapse Languages'), findsNothing);

    final searchField = tester.widget<TextField>(find.byType(TextField).first);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(searchField.controller!.text, isEmpty);
    expect(find.byTooltip('Collapse Languages'), findsOneWidget);
    expect(find.text('Topic 3'), findsOneWidget);
  });

  testWidgets('search threshold counts nested decks', (tester) async {
    final repository = _DeckRepository([
      DeckPickerDeck(
        id: 1,
        name: 'Root',
        children: [
          for (var id = 2; id <= 10; id++)
            DeckPickerDeck(id: id, name: 'Root::Topic $id'),
        ],
      ),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-picker-search')), findsOneWidget);
  });

  testWidgets('hiding search clears its active deck filter', (tester) async {
    final repository = _DeckRepository([
      for (var id = 1; id <= 10; id++)
        DeckPickerDeck(id: id, name: 'Topic $id'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Topic 1');
    await tester.pumpAndSettle();
    expect(find.text('Topic 2'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
    await tester.pumpAndSettle();

    expect(find.text('Topic 2'), findsOneWidget);
  });

  testWidgets(
    'open search retains a close control after refresh lowers count',
    (tester) async {
      final repository = _DeckRepository([
        for (var id = 1; id <= 10; id++)
          DeckPickerDeck(id: id, name: 'Topic $id'),
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Topic 1');
      final searchController = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!;
      await tester.pumpAndSettle();

      repository.decks.removeRange(1, repository.decks.length);
      await tester.tap(find.byTooltip('Refresh decks'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('deck-picker-search')), findsOneWidget);
      expect(find.byTooltip('Close search'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
      await tester.pumpAndSettle();
      expect(searchController.text, isEmpty);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Topic 1'), findsOneWidget);
    },
  );

  testWidgets('failed refresh leaves search closable and clears its query', (
    tester,
  ) async {
    final repository = _DeckRepository([
      for (var id = 1; id <= 10; id++)
        DeckPickerDeck(id: id, name: 'Topic $id'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-picker-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Topic 1');
    final searchController = tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!;
    await tester.pumpAndSettle();

    repository.failLoad = true;
    await tester.tap(find.byTooltip('Refresh decks'));
    await tester.pump();
    repository.completeFailure();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close search'), findsOneWidget);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(searchController.text, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('refresh clears selection when the selected deck was removed', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 1, name: 'Temporary'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-row-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('deck-study-selected')), findsOneWidget);

    repository.decks.clear();
    await tester.tap(find.byTooltip('Refresh decks'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-study-selected')), findsNothing);
  });

  testWidgets('pending selection cannot restore a deck removed by refresh', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 1, name: 'Temporary'),
    ])..pendingSelection = Completer<void>();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-row-1')));
    await tester.pump();

    repository.decks.clear();
    await tester.tap(find.byTooltip('Refresh decks'));
    await tester.pumpAndSettle();
    repository.pendingSelection!.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-study-selected')), findsNothing);
  });

  testWidgets('selection completing after refresh reconciles from host state', (
    tester,
  ) async {
    final repository =
        _DeckRepository([
            const DeckPickerDeck(id: 1, name: 'First'),
            const DeckPickerDeck(id: 2, name: 'Second'),
          ])
          ..currentDeckId = 1
          ..deferSelectionState = true
          ..pendingSelections[2] = Completer<void>();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-row-2')));
    await tester.pump();

    await tester.tap(find.byTooltip('Refresh decks'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('deck-row-1')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    repository.pendingSelections[2]!.complete();
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('deck-row-2')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets(
    'out-of-order selection responses keep the latest selected deck',
    (tester) async {
      final repository =
          _DeckRepository([
              const DeckPickerDeck(id: 1, name: 'First'),
              const DeckPickerDeck(id: 2, name: 'Second'),
            ])
            ..pendingSelections[1] = Completer<void>()
            ..pendingSelections[2] = Completer<void>();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deck-row-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('deck-row-2')));
      await tester.pump();

      repository.pendingSelections[2]!.complete();
      await tester.pumpAndSettle();
      repository.pendingSelections[1]!.complete();
      await tester.pumpAndSettle();

      expect(repository.selected, [1, 2]);
      expect(repository.currentDeckId, 2);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('deck-row-2')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('deck-row-1')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
    },
  );

  testWidgets('failed selection does not block the next queued request', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 1, name: 'First'),
      const DeckPickerDeck(id: 2, name: 'Second'),
    ])..failingSelections.add(1);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-row-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deck-row-2')));
    await tester.pumpAndSettle();

    expect(repository.selected, [2]);
    expect(repository.currentDeckId, 2);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('deck-row-2')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('new repository selections are independent of old pending work', (
    tester,
  ) async {
    final oldRepository = _DeckRepository([
      const DeckPickerDeck(id: 1, name: 'Old deck'),
    ])..pendingSelection = Completer<void>();
    await tester.pumpWidget(_app(oldRepository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-row-1')));
    await tester.pump();

    final newRepository = _DeckRepository([
      const DeckPickerDeck(id: 2, name: 'New deck'),
    ]);
    await tester.pumpWidget(_app(newRepository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deck-row-2')));
    await tester.pumpAndSettle();

    expect(newRepository.selected, [2]);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('deck-row-2')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    oldRepository.pendingSelection!.complete();
    await tester.pumpAndSettle();
    expect(newRepository.currentDeckId, 2);
  });

  testWidgets('deeply nested rows fit a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var deepest = const DeckPickerDeck(
      id: 8,
      name: 'Root::Child::Child::Child::Child::Child::Child::Leaf',
      newCount: 1,
      learningCount: 2,
      reviewCount: 3,
    );
    for (var id = 7; id >= 1; id--) {
      deepest = DeckPickerDeck(
        id: id,
        name: 'Root${List.filled(id, "::Child").join()}',
        newCount: 1,
        learningCount: 2,
        reviewCount: 3,
        children: [deepest],
      );
    }
    await tester.pumpWidget(_app(_DeckRepository([deepest])));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-row-8')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'custom study submits selected state, count and tag for exact deck',
    (tester) async {
      final deckId = Int64.parseInt('9007199254740995');
      final repository = _DeckRepository([
        DeckPickerDeck(id: 8, exactId: deckId, name: 'Biology'),
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More actions for Biology'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Custom study'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Custom study'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Study by card state or tag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '25');
      await tester.tap(find.bySemanticsLabel('Include exam'));
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(repository.customStudyDecks, [deckId, deckId]);
      expect(
        repository.customStudyRequests.single.state,
        CustomStudyCardState.NewCardsOnly,
      );
      expect(repository.customStudyRequests.single.cardLimit, 25);
      expect(repository.customStudyRequests.single.includedTags, ['exam']);
      expect(await SharedPreferencesAsync().getInt('amountOfCards'), 25);
    },
  );

  testWidgets('today limit extensions use signed int32 deltas for exact deck', (
    tester,
  ) async {
    final deckId = Int64.parseInt('9007199254740995');
    final repository = _DeckRepository([
      DeckPickerDeck(id: 8, exactId: deckId, name: 'Biology'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    Future<void> openExtendChoice(String title) async {
      await tester.tap(find.byTooltip('More actions for Biology'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Custom study'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Custom study'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }

    await openExtendChoice("Increase today's new card limit");
    await tester.enterText(
      find.byKey(const ValueKey('custom-study-limit-delta')),
      '2147483648',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'OK'))
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-study-limit-delta')),
      '2147483647',
    );
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(repository.customStudyLimitRequests.single.$1, deckId);
    expect(
      repository.customStudyLimitRequests.single.$2.kind,
      CustomStudyLimitKind.newCards,
    );
    expect(repository.customStudyLimitRequests.single.$2.delta, 2147483647);

    await openExtendChoice("Increase today's review card limit");
    await tester.enterText(
      find.byKey(const ValueKey('custom-study-limit-delta')),
      '-2147483648',
    );
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(repository.customStudyLimitRequests.last.$1, deckId);
    expect(
      repository.customStudyLimitRequests.last.$2.kind,
      CustomStudyLimitKind.reviewCards,
    );
    expect(repository.customStudyLimitRequests.last.$2.delta, -2147483648);
  });

  testWidgets(
    'Review Ahead disables Create until the selected period matches',
    (tester) async {
      final deckId = Int64.parseInt('9007199254740995');
      final repository = _DeckRepository([
        DeckPickerDeck(id: 8, exactId: deckId, name: 'Biology'),
      ])..reviewAheadMatches = false;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More actions for Biology'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Custom study'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Custom study'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review ahead'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      final create = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create'),
      );
      expect(create.onPressed, isNull);
      expect(
        find.text('No cards matched the criteria you provided.'),
        findsOneWidget,
      );

      repository.reviewAheadMatches = true;
      await tester.enterText(find.byType(TextField).last, '3');
      await tester.pumpAndSettle();
      final enabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create'),
      );
      expect(enabled.onPressed, isNotNull);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(repository.reviewAheadRequests, [(deckId, 3)]);
      expect(await SharedPreferencesAsync().getInt('aheadDays'), 3);
    },
  );

  testWidgets('forgotten card custom study creates the selected day window', (
    tester,
  ) async {
    final deckId = Int64.parseInt('9007199254740995');
    final repository = _DeckRepository([
      DeckPickerDeck(id: 8, exactId: deckId, name: 'Biology'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Custom study'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Custom study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review forgotten cards'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('Days to look back'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '07');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(repository.forgottenCardsRequests, [(deckId, 7)]);
    expect(await SharedPreferencesAsync().getInt('forgottenDays'), 7);
  });

  testWidgets('preview new cards creates the selected day window', (
    tester,
  ) async {
    final deckId = Int64.parseInt('9007199254740995');
    final repository = _DeckRepository([
      DeckPickerDeck(id: 8, exactId: deckId, name: 'Biology'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Custom study'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Custom study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview new cards'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('Days since added'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '7');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(repository.previewNewCardsRequests, [(deckId, 7)]);
    expect(await SharedPreferencesAsync().getInt('previewDays'), 7);
  });

  testWidgets('deck action menu forwards its source action and deck ID', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(
        id: 8,
        name: 'Biology',
        newCount: 1,
        learningCount: 2,
        reviewCount: 3,
      ),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse cards'));
    await tester.pumpAndSettle();
    expect(repository.actions, [(DeckPickerAction.browseCards, 8)]);
  });

  testWidgets(
    'empty filtered deck action preserves ID and reloads deck state',
    (tester) async {
      final filtered = DeckPickerDeck(
        id: 42,
        exactId: Int64.parseInt('9007199254740995'),
        name: 'Filtered',
        filtered: true,
        reviewCount: 3,
      );
      final repository = _DeckRepository([
        const DeckPickerDeck(id: 8, name: 'Ordinary'),
        filtered,
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions for Ordinary'));
      await tester.pumpAndSettle();
      expect(find.text('Empty filtered deck'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions for Filtered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empty filtered deck'));
      await tester.pumpAndSettle();

      expect(repository.emptyFilteredExact, [
        Int64.parseInt('9007199254740995'),
      ]);
      expect(repository.loadCalls, 2);
    },
  );

  testWidgets('rename dialog validates names and refreshes after success', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Biology'),
      const DeckPickerDeck(id: 9, name: 'Chemistry'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename deck'));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('rename-deck-name'));
    final input = find.descendant(of: field, matching: find.byType(TextField));
    expect(tester.widget<TextField>(input).controller!.text, 'Biology');
    expect(find.text('A deck with this name already exists'), findsNothing);
    final renameButton = find.widgetWithText(FilledButton, 'Rename');

    await tester.enterText(input, '');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(renameButton).onPressed, isNull);
    expect(find.text('A deck with this name already exists'), findsNothing);
    await tester.enterText(input, 'Chemistry');
    await tester.pumpAndSettle();
    expect(find.text('A deck with this name already exists'), findsOneWidget);
    expect(tester.widget<FilledButton>(renameButton).onPressed, isNull);

    await tester.enterText(input, 'Biology::Genetics');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(renameButton).onPressed, isNotNull);
    await tester.tap(renameButton);
    await tester.pumpAndSettle();

    expect(repository.renamedNames, ['Biology::Genetics']);
    expect(repository.loadCalls, 2);
    expect(repository.decks.first.name, 'Biology::Genetics');
  });

  testWidgets('canceling rename makes no repository call', (tester) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Biology'),
    ]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.renamedNames, isEmpty);
    expect(repository.loadCalls, 1);
  });

  testWidgets('rename reloads after a committed write reports a flush error', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Biology'),
    ])..failRenameAfterUpdate = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename deck'));
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: find.byKey(const ValueKey('rename-deck-name')),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, 'Biology renamed');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(repository.decks.first.name, 'Biology renamed');
    expect(repository.loadCalls, 2);
    expect(find.text('Deck action could not be completed'), findsOneWidget);
  });

  testWidgets('browsing passes the selected deck without selecting it', (
    tester,
  ) async {
    final repository = _DeckRepository([
      const DeckPickerDeck(id: 8, name: 'Biology'),
    ]);
    final browsed = <Int64>[];
    await tester.pumpWidget(_app(repository, onBrowseCards: browsed.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Biology'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse cards'));
    await tester.pumpAndSettle();

    expect(repository.selected, isEmpty);
    expect(repository.selectedExact, [Int64(8)]);
    expect(repository.actions, isEmpty);
    expect(browsed, [Int64(8)]);
  });

  testWidgets('browsing preserves an exact wide deck ID through navigation', (
    tester,
  ) async {
    const placeholderId = 8;
    final exactId = Int64(9007199254740995);
    final repository = _DeckRepository([
      DeckPickerDeck(id: placeholderId, exactId: exactId, name: 'Wide'),
    ]);
    final browsed = <Int64>[];
    await tester.pumpWidget(_app(repository, onBrowseCards: browsed.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions for Wide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse cards'));
    await tester.pumpAndSettle();

    expect(repository.selectedExact, [exactId]);
    expect(browsed, [exactId]);
  });

  testWidgets('narrow viewport golden', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        _DeckRepository([
          const DeckPickerDeck(
            id: 1,
            name: 'Languages',
            newCount: 2,
            learningCount: 3,
            reviewCount: 4,
            children: [
              DeckPickerDeck(
                id: 2,
                name: 'Languages::Spanish',
                newCount: 1,
                learningCount: 0,
                reviewCount: 5,
              ),
            ],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DeckPickerScreen),
      matchesGoldenFile('goldens/deck_picker_narrow.png'),
    );
  });

  testWidgets('wide viewport golden', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        _DeckRepository([
          const DeckPickerDeck(
            id: 1,
            name: 'Languages',
            newCount: 2,
            learningCount: 3,
            reviewCount: 4,
            children: [
              DeckPickerDeck(
                id: 2,
                name: 'Languages::Spanish',
                newCount: 1,
                learningCount: 0,
                reviewCount: 5,
              ),
            ],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DeckPickerScreen),
      matchesGoldenFile('goldens/deck_picker_wide.png'),
    );
  });
}

Widget _app(
  DeckPickerRepository repository, {
  ValueChanged<Int64>? onBrowseCards,
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: DeckPickerScreen(repository: repository, onBrowseCards: onBrowseCards),
);

final class _DeckRepository
    implements
        DeckPickerRepository,
        DeckPickerNewNotePortProvider,
        DeckPickerExactBrowseDeckProvider,
        DeckPickerCreateSubdeckProvider,
        DeckPickerRenameProvider,
        DeckPickerDeleteProvider,
        DeckPickerUnburyProvider,
        DeckPickerEmptyFilteredDeckProvider,
        DeckPickerDescriptionProvider,
        DeckPickerCustomStudyProvider,
        DeckPickerReviewAheadProvider,
        DeckPickerForgottenCardsProvider,
        DeckPickerPreviewNewCardsProvider,
        DeckPickerExtendLimitsProvider,
        DeckPickerDailyLimitsProvider,
        DeckPickerCollectionUndoProvider {
  _DeckRepository(this.decks);
  NewNoteEditorPort? editorPort;
  @override
  bool get scheduleRemindersEnabled => false;
  @override
  int? currentDeckId;
  @override
  FilteredDeckOptions newFilteredDeckOptions = const FilteredDeckOptions(
    cardOptions: ['Host order A', 'Host order B', 'Host order C'],
  );
  List<int> filteredOrderNumbers = [0, 1, 2];
  @override
  List<FilteredDeckOrderOption> get filteredDeckOrderOptions => [
    for (
      var index = 0;
      index < newFilteredDeckOptions.cardOptions.length &&
          index < filteredOrderNumbers.length;
      index++
    )
      FilteredDeckOrderOption(
        orderNumber: filteredOrderNumbers[index],
        label: newFilteredDeckOptions.cardOptions[index],
      ),
  ];
  final List<DeckPickerDeck> decks;
  int loadCalls = 0;
  bool pendingLoad = false;
  bool failLoad = false;
  bool failRenameAfterUpdate = false;
  bool failDelete = false;
  bool failUnbury = false;
  bool failDescriptionLoad = false;
  bool failDescriptionSave = false;
  String description = '';
  bool markdownDescription = false;
  final descriptionLoads = <Int64>[];
  final savedDescriptionIds = <Int64>[];
  final emptyFilteredExact = <Int64>[];
  bool deferSelectionState = false;
  final failingSelections = <int>{};
  Completer<void>? pendingSelection;
  Completer<List<DeckPickerDeck>>? _pending;
  Completer<List<DeckPickerDeck>>? _failure;
  final pendingSelections = <int, Completer<void>>{};
  final studied = <int>[];
  final selected = <int>[];
  final selectedExact = <Int64>[];
  int currentDeckNewNoteRequests = 0;
  final actions = <(DeckPickerAction, int)>[];
  final createdSubdecks = <(Int64, String)>[];
  bool failNextSubdeck = false;
  final renamedNames = <String>[];
  final filteredRequests = <FilteredDeckRequest>[];
  final customStudyDecks = <Int64>[];
  final customStudyRequests = <CustomStudyTagsRequest>[];
  bool reviewAheadMatches = true;
  final reviewAheadRequests = <(Int64, int)>[];
  bool forgottenCardsMatch = true;
  final forgottenCardsRequests = <(Int64, int)>[];
  final previewNewCardsRequests = <(Int64, int)>[];
  Completer<DeckPickerDeletionResult>? pendingDelete;
  Completer<DeckPickerUnburyResult>? pendingUnbury;
  final deletedExact = <Int64>[];
  final unburiedExact = <Int64>[];
  DeckPickerDeck? _deletedDeck;
  @override
  bool canUndoCollectionOperation = false;
  @override
  bool canRedoCollectionOperation = false;
  @override
  int collectionUndoGeneration = 0;
  bool advanceUndoGenerationAfterDelete = false;
  int undoCalls = 0;
  final dailyLimitLoads = <Int64>[];
  final dailyLimitSaves = <(Int64, int, int)>[];
  int newLimit = 34;
  int reviewLimit = 187;
  final customStudyLimitRequests = <(Int64, CustomStudyLimitRequest)>[];
  @override
  Future<CustomStudyLimitDefaults> customStudyLimitDefaults(
    DeckPickerDeck deck,
  ) async => const CustomStudyLimitDefaults(
    extendNew: 3,
    extendReview: 4,
    availableNew: 2,
    availableReview: 5,
    availableNewInChildren: 1,
    availableReviewInChildren: 0,
  );
  @override
  Future<void> extendTodayLimits(
    DeckPickerDeck deck,
    CustomStudyLimitRequest request,
  ) async =>
      customStudyLimitRequests.add((deck.exactId ?? Int64(deck.id), request));

  @override
  Future<NewNoteEditorPort> selectDeckAndCreateNewNotePort(
    DeckPickerDeck deck,
  ) async {
    selected.add(deck.id);
    currentDeckId = deck.id;
    selectedExact.add(deck.exactId ?? Int64(deck.id));
    return editorPort!;
  }

  @override
  Future<NewNoteEditorPort> createNewNotePortForCurrentDeck() async {
    currentDeckNewNoteRequests++;
    return editorPort!;
  }

  @override
  Future<void> selectDeckForBrowse(DeckPickerDeck deck) async {
    selectedExact.add(deck.exactId ?? Int64(deck.id));
  }

  @override
  bool isSubdeckNameAvailable(DeckPickerDeck parent, String name) =>
      name.isNotEmpty && name.replaceAll('"', '').isNotEmpty;

  @override
  Future<void> createSubdeck(DeckPickerDeck parent, String name) async {
    if (failNextSubdeck) {
      failNextSubdeck = false;
      throw StateError('subdeck creation failed');
    }
    createdSubdecks.add((parent.exactId ?? Int64(parent.id), name));
  }

  @override
  Future<List<DeckPickerDeck>> loadDecks() {
    loadCalls++;
    if (pendingLoad) {
      return (_pending = Completer<List<DeckPickerDeck>>()).future;
    }
    if (failLoad) return (_failure = Completer<List<DeckPickerDeck>>()).future;
    return Future.value(decks);
  }

  void completeLoad(List<DeckPickerDeck> result) {
    pendingLoad = false;
    _pending?.complete(result);
  }

  void completeFailure() => _failure!.completeError(StateError('load failed'));

  @override
  Future<void> selectDeck(int deckId) async {
    if (!deferSelectionState) currentDeckId = deckId;
    await pendingSelection?.future;
    await pendingSelections[deckId]?.future;
    if (failingSelections.contains(deckId)) {
      throw StateError('selection failed');
    }
    selected.add(deckId);
    if (deferSelectionState) currentDeckId = deckId;
  }

  @override
  Future<void> study(int deckId) async => studied.add(deckId);
  @override
  Future<void> toggleDeckExpand(int deckId) async {}
  @override
  Future<void> performAction(DeckPickerAction action, int deckId) async =>
      actions.add((action, deckId));

  @override
  Future<DeckDescription> loadDescription(DeckPickerDeck deck) async {
    final id = deck.exactId ?? Int64(deck.id);
    descriptionLoads.add(id);
    if (failDescriptionLoad) throw StateError('description load failed');
    return DeckDescription(
      description: description,
      markdown: markdownDescription,
    );
  }

  @override
  Future<void> saveDescription(
    DeckPickerDeck deck, {
    required String description,
    required bool markdownDescription,
  }) async {
    savedDescriptionIds.add(deck.exactId ?? Int64(deck.id));
    if (failDescriptionSave) throw StateError('description save failed');
    this.description = description;
    this.markdownDescription = markdownDescription;
  }

  @override
  Future<DeckDailyLimits> loadDailyLimits(DeckPickerDeck deck) async {
    dailyLimitLoads.add(deck.exactId ?? Int64(deck.id));
    return DeckDailyLimits(newPerDay: newLimit, reviewsPerDay: reviewLimit);
  }

  @override
  Future<void> saveDailyLimits(
    DeckPickerDeck deck, {
    required int newPerDay,
    required int reviewsPerDay,
  }) async {
    dailyLimitSaves.add((
      deck.exactId ?? Int64(deck.id),
      newPerDay,
      reviewsPerDay,
    ));
    newLimit = newPerDay;
    reviewLimit = reviewsPerDay;
  }

  @override
  Future<DeckPickerDeletionResult> deleteDeck(
    DeckPickerDeck deck, {
    required String defaultDeckName,
  }) async {
    deletedExact.add(deck.exactId ?? Int64(deck.id));
    if (failDelete) throw StateError('delete failed');
    final result =
        await (pendingDelete?.future ??
            Future.value(
              DeckPickerDeletionResult(
                deckName: deck.name,
                cardsDeleted:
                    deck.newCount + deck.learningCount + deck.reviewCount,
                collectionUndoGeneration: collectionUndoGeneration + 1,
              ),
            ));
    _deletedDeck = deck;
    decks.removeWhere((candidate) => candidate.id == deck.id);
    currentDeckId = 1;
    canUndoCollectionOperation = true;
    canRedoCollectionOperation = false;
    collectionUndoGeneration++;
    if (advanceUndoGenerationAfterDelete) collectionUndoGeneration++;
    return result.collectionUndoGeneration == 0
        ? DeckPickerDeletionResult(
            deckName: result.deckName,
            cardsDeleted: result.cardsDeleted,
            collectionUndoGeneration: collectionUndoGeneration,
            persistenceWarning: result.persistenceWarning,
          )
        : result;
  }

  @override
  Future<DeckPickerUnburyResult> unburyDeck(DeckPickerDeck deck) async {
    unburiedExact.add(deck.exactId ?? Int64(deck.id));
    if (failUnbury) throw StateError('unbury failed');
    final result =
        await (pendingUnbury?.future ??
            Future.value(
              DeckPickerUnburyResult(
                deckName: deck.name,
                cardsUnburied: 1,
                collectionUndoGeneration: collectionUndoGeneration + 1,
              ),
            ));
    canUndoCollectionOperation = true;
    canRedoCollectionOperation = false;
    collectionUndoGeneration++;
    return result;
  }

  @override
  Future<void> emptyFilteredDeck(DeckPickerDeck deck) async {
    emptyFilteredExact.add(deck.exactId ?? Int64(deck.id));
  }

  @override
  Future<void> undoLastCollectionOperation() async {
    undoCalls++;
    if (_deletedDeck != null) decks.add(_deletedDeck!);
    currentDeckId = _deletedDeck?.id;
    canUndoCollectionOperation = false;
    canRedoCollectionOperation = true;
    collectionUndoGeneration++;
  }

  @override
  Future<void> redoLastCollectionOperation() async {
    final deck = _deletedDeck;
    if (deck != null) decks.removeWhere((candidate) => candidate.id == deck.id);
    currentDeckId = 1;
    canUndoCollectionOperation = true;
    canRedoCollectionOperation = false;
    collectionUndoGeneration++;
  }

  @override
  bool isDeckNameAvailable(DeckPickerDeck deck, String name) {
    if (name.trim().isEmpty) return false;
    final normalized = normalizeDeckName(name);
    return !decks.any(
      (candidate) =>
          candidate.id != deck.id &&
          normalizeDeckName(candidate.name) == normalized,
    );
  }

  @override
  Future<void> renameDeck(DeckPickerDeck deck, String name) async {
    renamedNames.add(name);
    final index = decks.indexWhere((candidate) => candidate.id == deck.id);
    decks[index] = DeckPickerDeck(
      id: deck.id,
      exactId: deck.exactId,
      name: normalizeDeckName(name),
      newCount: deck.newCount,
      learningCount: deck.learningCount,
      reviewCount: deck.reviewCount,
      children: deck.children,
      filtered: deck.filtered,
      collapsed: deck.collapsed,
      hasBuried: deck.hasBuried,
    );
    if (failRenameAfterUpdate) throw StateError('flush failed after commit');
  }

  @override
  Future<List<String>> customStudyTags(DeckPickerDeck deck) async {
    customStudyDecks.add(deck.exactId ?? Int64(deck.id));
    return ['exam', 'leech'];
  }

  @override
  Future<void> createCustomStudy(
    DeckPickerDeck deck,
    CustomStudyTagsRequest request,
  ) async {
    customStudyDecks.add(deck.exactId ?? Int64(deck.id));
    customStudyRequests.add(request);
  }

  @override
  Future<bool> hasReviewAheadCards(DeckPickerDeck deck, int days) async =>
      reviewAheadMatches;

  @override
  Future<void> createReviewAhead(DeckPickerDeck deck, int days) async =>
      reviewAheadRequests.add((deck.exactId ?? Int64(deck.id), days));

  @override
  Future<bool> hasForgottenCards(DeckPickerDeck deck, int days) async =>
      forgottenCardsMatch;

  @override
  Future<void> createForgottenCards(DeckPickerDeck deck, int days) async =>
      forgottenCardsRequests.add((deck.exactId ?? Int64(deck.id), days));

  @override
  @override
  Future<void> createPreviewNewCards(DeckPickerDeck deck, int days) async =>
      previewNewCardsRequests.add((deck.exactId ?? Int64(deck.id), days));

  @override
  Future<void> createDeck(String name) async {}
  @override
  Future<void> createSharedDeck() async {}
  @override
  Future<void> buildFilteredDeck(FilteredDeckRequest request) async =>
      filteredRequests.add(request);
}

final class _FakeDeckPickerNewNotePort implements NewNoteEditorPort {
  int loadCalls = 0;

  @override
  Future<List<NewNoteEditorDeck>> loadSelectableDecks() async => [
    NewNoteEditorDeck(id: Int64(42), name: 'Selected'),
  ];

  @override
  Future<NewNoteEditorDraft> loadNewNote() async {
    loadCalls++;
    return NewNoteEditorDraft(
      notetypeId: Int64.ONE,
      deckId: Int64(42),
      content: NoteEditorContent(labels: const ['Front'], values: const ['']),
    );
  }

  @override
  Future<NewNoteEditorDraft> changeNewNoteType({
    required NewNoteEditorDraft draft,
    required Int64 notetypeId,
    required List<String> fields,
    required List<String> tags,
  }) => Future.error(UnimplementedError());

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
  }) async => 1;

  @override
  Future<NoteEditorContent> loadNote(Int64 noteId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> saveNote(Int64 noteId, List<String> fields, List<String> tags) =>
      Future.error(UnimplementedError());
}
