/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';

import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/note_editor_screen.dart';
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new note loads the selected type, deck, empty fields and tags', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();

    expect(port.loadedDrafts, 1);
    expect(port.lastNotetypeId, Int64(12));
    expect(port.lastDeckId, Int64(34));
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('selected'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-0')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets(
    'new-note type selection refreshes labels and values with exact ID',
    (tester) async {
      final port = _FakeNewNoteEditorPort();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('note-field-0')),
        'kept value',
      );
      await tester.tap(find.byKey(const Key('note-editor-tags')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-select-Science::Chemistry')));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-editor-select-note-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cloze').last);
      await tester.pumpAndSettle();

      expect(port.lastNotetypeId, Int64.parseInt('9007199254740993'));
      expect(find.text('Text'), findsOneWidget);
      expect(find.byKey(const Key('note-field-1')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-field-0')))
            .controller!
            .text,
        'kept value',
      );
      expect(
        find.byKey(const Key('note-editor-tag-Science::Chemistry')),
        findsOneWidget,
      );
    },
  );

  testWidgets('failed type change restores the selected type display', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort()..failTypeChange = true;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-select-note-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cloze').last);
    await tester.pumpAndSettle();

    expect(find.text('Basic'), findsOneWidget);
    expect(port.lastNotetypeId, Int64(12));
    expect(find.text('Front'), findsOneWidget);
  });

  testWidgets('new note deck choice keeps exact ID and draft edits', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort()
      ..validation = const NoteFieldsCheckSuccess();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field-0')), 'draft');
    await tester.tap(find.byKey(const Key('note-editor-tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-select-Science::Chemistry')));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-select-deck')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('note-editor-deck-9007199254740993')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Course::Unit'), findsOneWidget);
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();

    expect(port.lastSavedDeckId, Int64.parseInt('9007199254740993'));
    expect(port.lastFields, ['draft', '']);
    expect(port.lastTags, ['Science::Chemistry']);
  });

  testWidgets('canceling deck selection preserves the resolved destination', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-select-deck')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Default'), findsOneWidget);
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(port.lastSavedDeckId, Int64(34));
  });

  testWidgets('deck catalog load failure can be retried', (tester) async {
    final port = _FakeNewNoteEditorPort()..failDeckLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-select-deck')));
    await tester.pumpAndSettle();
    expect(find.text('Decks could not be loaded.'), findsOneWidget);

    port.failDeckLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-editor-deck-34')), findsOneWidget);
    expect(port.deckLoadCalls, 2);
  });

  testWidgets('empty deck catalog explains that no choices are available', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort()..deckCatalog = const [];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-select-deck')));
    await tester.pumpAndSettle();

    expect(find.text('No selectable decks are available.'), findsOneWidget);
    expect(find.byKey(const Key('note-editor-deck-34')), findsNothing);
  });

  testWidgets('new note validates and treats duplicate as nonfatal', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort()
      ..validation = const NoteFieldsCheckSuccess();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field-0')), 'front');
    await tester.tap(find.byKey(const Key('note-editor-tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-select-Science::Chemistry')));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    port.validation = const NoteFieldsCheckSuccess(); // NORMAL or DUPLICATE.
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();

    expect(port.validationCalls, 1);
    expect(port.addCalls, 1);
    expect(port.lastFields, ['front', '']);
    expect(port.lastTags, ['Science::Chemistry']);
  });

  testWidgets('new note keeps edits after validation and storage failures', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort()
      ..validation = const NoteFieldsCheckFailure('First field is empty.');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field-0')), 'draft');
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(port.addCalls, 0);
    expect(find.text('First field is empty.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-0')))
          .controller!
          .text,
      'draft',
    );

    port.validation = const NoteFieldsCheckSuccess();
    port.failAdd = true;
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('Changes could not be saved. Try again.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-0')))
          .controller!
          .text,
      'draft',
    );
  });

  testWidgets('new note save is single-flight and resets after success', (
    tester,
  ) async {
    final port = _FakeNewNoteEditorPort()
      ..pendingAdd = Completer<int>()
      ..validation = const NoteFieldsCheckSuccess();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NoteEditorScreen.newNote(newNotePort: port)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field-0')), 'front');
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pump();
    await _scrollToEditorSave(tester);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    expect(port.addCalls, 1);
    port.pendingAdd!.complete(2);
    await tester.pumpAndSettle();

    expect(port.addCalls, 1);
    expect(port.loadedDrafts, 2);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      (tester.widget<SnackBar>(find.byType(SnackBar)).content as Text).data,
      'Added note. Cards created: 2',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-0')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets(
    'committed add failure explains pending storage and blocks exit',
    (tester) async {
      final port = _FakeNewNoteEditorPort()
        ..failAddAfterCommit = true
        ..validation = const NoteFieldsCheckSuccess();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => NoteEditorScreen.newNote(newNotePort: port),
                  ),
                ),
                child: const Text('Open add editor'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open add editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('note-field-0')),
        'will be committed',
      );
      await _scrollToEditorSave(tester);
      await tester.tap(find.byKey(const Key('note-editor-save')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The note was added, but saving it to storage failed. Retry Save before leaving.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('note-editor-select-deck')),
            )
            .onPressed,
        isNull,
      );

      port.failAddAfterCommit = false;
      await tester.drag(find.byType(ListView).first, const Offset(0, -140));
      await tester.pumpAndSettle();
      await _scrollToEditorSave(tester);
      await tester.tap(find.byKey(const Key('note-editor-save')));
      await tester.pumpAndSettle();
      expect(port.addCalls, 2);
      expect(port.loadedDrafts, 2);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    },
  );

  testWidgets('shows fields in notetype order and saves edited values', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NoteEditorScreen(noteId: Int64(7), port: port),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('note-editor-select-note-type')), findsNothing);

    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.byTooltip('Undo note edit'), findsNothing);
    expect(find.byTooltip('Redo note edit'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-0')))
          .controller!
          .text,
      'front value',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-field-1')))
          .controller!
          .text,
      'back value',
    );

    await tester.enterText(
      find.byKey(const Key('note-field-0')),
      'updated front',
    );
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();

    expect(port.savedNoteId, Int64(7));
    expect(port.savedFields, ['updated front', 'back value']);
    expect(find.text('Open editor'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('selects tags in a searchable dialog and saves confirmed tags', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NoteEditorScreen(noteId: Int64(7), port: port),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-editor-tags')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tag-filter')), 'Science');
    expect(find.text('Science::Chemistry'), findsOneWidget);
    expect(find.byKey(const Key('tag-select-Science')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tag-select-Science::Chemistry')));
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('tag-select-Science')))
          .value,
      isNull,
    );
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-tag-name')),
      'science :: chemistry',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('This tag already exists'), findsOneWidget);
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-tag-name')), 'ı');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('This tag already exists'), findsOneWidget);
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-tag-name')), 'New::Child');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Science::Chemistry'), findsOneWidget);
    final selectedTagChip = tester.widget<InputChip>(
      find.byKey(const Key('note-editor-tag-selected')),
    );
    selectedTagChip.onDeleted!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-editor-tag-New::Child')), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(port.savedTags, containsAll(['Science::Chemistry', 'New::Child']));
    expect(port.savedTags, isNot(contains('selected')));
  });

  testWidgets('canceling tag selection and saving unchanged tags keeps them', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NoteEditorScreen(noteId: Int64(7), port: port),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-select-selected')));
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(port.savedTags, ['selected']);
  });

  testWidgets('confirming unchanged hierarchical tags preserves their order', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort()..tags = ['a::z', 'a-b'];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NoteEditorScreen(noteId: Int64(7), port: port),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();

    expect(port.savedTags, ['a::z', 'a-b']);
  });

  testWidgets('rejects empty and whitespace-only tag input', (tester) async {
    final port = _FakeNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NoteEditorScreen(noteId: Int64(7), port: port),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-editor-tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('new-tag-name')), '   ');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a tag name'), findsOneWidget);
    expect(find.text('blank'), findsNothing);
  });

  testWidgets('load and save failures stay recoverable in the editor', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort()..failLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NoteEditorScreen(noteId: Int64(7), port: port),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('This note could not be loaded from the active collection.'),
      findsOneWidget,
    );

    port.failLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    port.failSave = true;
    await tester.enterText(find.byKey(const Key('note-field-0')), 'edited');
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('Changes could not be saved. Try again.'), findsOneWidget);
    expect(find.byKey(const Key('note-field-0')), findsOneWidget);
    port.failSave = false;
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pumpAndSettle();
    expect(port.savedFields, ['edited', 'back value']);
  });

  testWidgets('cancel closes the editor without saving', (tester) async {
    final port = _FakeNoteEditorPort();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NoteEditorScreen(noteId: Int64(7), port: port),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field-0')), 'discarded');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Open editor'), findsOneWidget);
    expect(port.savedFields, isNull);
  });

  testWidgets('locks field values while an asynchronous save is pending', (
    tester,
  ) async {
    final port = _FakeNoteEditorPort()..pendingSave = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NoteEditorScreen(noteId: Int64(7), port: port),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field-0')), 'submitted');
    await tester.tap(find.byKey(const Key('note-editor-save')));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byKey(const Key('note-field-0'))).enabled,
      isFalse,
    );
    expect(find.text('Saving…'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(NoteEditorScreen), findsOneWidget);

    port.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(port.savedFields, ['submitted', 'back value']);
  });
}

final class _FakeNoteEditorPort implements NoteEditorPort {
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? pendingSave;
  Int64? savedNoteId;
  List<String>? savedFields;
  List<String>? savedTags;
  List<String> tags = ['selected'];

  @override
  Future<NoteEditorContent> loadNote(Int64 noteId) async {
    if (failLoad) throw StateError('unavailable');
    return NoteEditorContent(
      labels: const ['Front', 'Back'],
      values: const ['front value', 'back value'],
      tags: tags,
      availableTags: const [
        'selected',
        'Science::Chemistry',
        'Science::Biology',
        'I',
      ],
    );
  }

  @override
  Future<void> saveNote(
    Int64 noteId,
    List<String> fields,
    List<String> tags,
  ) async {
    if (failSave) throw StateError('write failed');
    await pendingSave?.future;
    savedNoteId = noteId;
    savedFields = fields;
    savedTags = tags;
  }
}

final class _FakeNewNoteEditorPort implements NewNoteEditorPort {
  final _FakeNoteEditorPort _existing = _FakeNoteEditorPort();
  int loadedDrafts = 0;
  int validationCalls = 0;
  int addCalls = 0;
  bool failTypeChange = false;
  bool failAdd = false;
  bool failDeckLoad = false;
  bool failAddAfterCommit = false;
  int deckLoadCalls = 0;
  List<NewNoteEditorDeck> deckCatalog = [
    NewNoteEditorDeck(id: Int64(34), name: 'Default'),
    NewNoteEditorDeck(
      id: Int64.parseInt('9007199254740993'),
      name: 'Course::Unit',
    ),
  ];
  Completer<int>? pendingAdd;
  NoteFieldsCheckResult validation = const NoteFieldsCheckSuccess();
  Int64? lastNotetypeId;
  Int64? lastDeckId;
  Int64? lastSavedDeckId;
  List<String>? lastFields;
  List<String>? lastTags;

  @override
  Future<NewNoteEditorDraft> loadNewNote() async {
    loadedDrafts++;
    lastNotetypeId = Int64(12);
    lastDeckId = Int64(34);
    return NewNoteEditorDraft(
      notetypeId: lastNotetypeId!,
      deckId: lastDeckId!,
      deckName: 'Default',
      noteTypes: [
        NewNoteEditorNoteType(id: Int64(12), name: 'Basic'),
        NewNoteEditorNoteType(
          id: Int64.parseInt('9007199254740993'),
          name: 'Cloze',
        ),
      ],
      note: models.Note(notetypeId: lastNotetypeId!, fields: const ['', '']),
      content: NoteEditorContent(
        labels: const ['Front', 'Back'],
        values: const ['', ''],
        availableTags: const ['selected', 'Science::Chemistry'],
      ),
    );
  }

  @override
  Future<NewNoteEditorDraft> changeNewNoteType({
    required NewNoteEditorDraft draft,
    required Int64 notetypeId,
    required List<String> fields,
    required List<String> tags,
  }) async {
    if (failTypeChange) throw StateError('type change failed');
    lastNotetypeId = notetypeId;
    final labels = notetypeId == Int64.parseInt('9007199254740993')
        ? const ['Text']
        : const ['Front', 'Back'];
    final nextFields = List<String>.of(fields.take(labels.length));
    while (nextFields.length < labels.length) {
      nextFields.add('');
    }
    final note = models.Note(
      notetypeId: notetypeId,
      fields: nextFields,
      tags: tags,
    );
    return NewNoteEditorDraft(
      notetypeId: notetypeId,
      deckId: draft.deckId,
      deckName: draft.deckName,
      note: note,
      noteTypes: draft.noteTypes,
      content: NoteEditorContent(
        labels: labels,
        values: nextFields,
        tags: tags,
        availableTags: const ['selected', 'Science::Chemistry'],
      ),
    );
  }

  @override
  Future<List<NewNoteEditorDeck>> loadSelectableDecks() async {
    deckLoadCalls++;
    if (failDeckLoad) throw StateError('deck catalog unavailable');
    return deckCatalog;
  }

  @override
  Future<NoteFieldsCheckResult> validateNewNote(
    Int64 notetypeId,
    List<String> fields,
  ) async {
    validationCalls++;
    return validation;
  }

  @override
  Future<int> saveNewNote({
    required NewNoteEditorDraft draft,
    required List<String> fields,
    required List<String> tags,
  }) async {
    addCalls++;
    lastSavedDeckId = draft.deckId;
    if (failAddAfterCommit) {
      draft.note!.id = Int64(456);
      throw StateError('driver flush failed after commit');
    }
    if (failAdd) throw StateError('write failed');
    lastFields = fields;
    lastTags = tags;
    return pendingAdd?.future ?? 2;
  }

  @override
  Future<NoteEditorContent> loadNote(Int64 noteId) =>
      _existing.loadNote(noteId);

  @override
  Future<void> saveNote(Int64 noteId, List<String> fields, List<String> tags) =>
      _existing.saveNote(noteId, fields, tags);
}

Future<void> _scrollToEditorSave(WidgetTester tester) async {
  final save = find.byKey(const Key('note-editor-save'));
  if (save.evaluate().isNotEmpty) {
    await tester.ensureVisible(save);
    return;
  }
  await tester.scrollUntilVisible(
    save,
    250,
    scrollable: find.byType(Scrollable).first,
  );
}
