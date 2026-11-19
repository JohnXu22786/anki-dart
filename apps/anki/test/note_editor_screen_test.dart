/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';

import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/note_editor_screen.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
