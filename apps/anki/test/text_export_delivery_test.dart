/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/collection_text_export.dart';
import 'package:anki_app/text_export_delivery.dart';
import 'package:anki_app/text_export_ready_dialog.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/deck_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  setUp(() {
    final factory = newDatabaseFactoryMemory();
    PendingTextExportStore.instance = PendingTextExportStore(
      openDatabase: () => factory.openDatabase('test'),
    );
  });

  test('Notes and Cards artifacts preserve text as UTF-8 text files', () {
    for (final (format, expectedName) in [
      (DeckPickerExportFormat.notes, 'notes.txt'),
      (DeckPickerExportFormat.cards, 'cards.txt'),
    ]) {
      final request = _request(format);
      final artifact = createDeckPickerTextExportArtifact(
        request,
        const CollectionTextExportResult(text: '漢字\n', count: 1),
      );

      expect(artifact.fileName, expectedName);
      expect(artifact.text, '漢字\n');
      expect(artifact.bytes, utf8.encode('漢字\n'));
      expect(artifact.mimeType, 'text/plain');
    }
  });

  testWidgets('Save and Share choices forward the exact artifact', (
    tester,
  ) async {
    final artifact = _artifact();
    final delivery = _FakeDelivery();
    await tester.pumpWidget(_app(artifact, delivery));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(delivery.saved, same(artifact));
    expect(find.byType(TextExportReadyDialog), findsNothing);

    await tester.pumpWidget(_app(artifact, delivery));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(delivery.shared, same(artifact));
  });

  testWidgets('dismissal and errors do not report success and can be retried', (
    tester,
  ) async {
    final artifact = _artifact();
    final delivery = _FakeDelivery()
      ..nextSaveResult = false
      ..nextShareError = StateError('share failed');
    await tester.pumpWidget(_app(artifact, delivery));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(TextExportReadyDialog), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not deliver the export. Try again.'),
      findsOneWidget,
    );
    expect(find.byType(TextExportReadyDialog), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(delivery.shared, same(artifact));
    expect(find.byType(TextExportReadyDialog), findsNothing);
  });

  test('unsupported package formats cannot create a ready artifact', () {
    expect(
      () => createDeckPickerTextExportArtifact(
        _request(DeckPickerExportFormat.apkg),
        const CollectionTextExportResult(text: 'placeholder', count: 0),
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => createDeckPickerTextExportArtifact(
        _request(DeckPickerExportFormat.collection),
        const CollectionTextExportResult(text: 'placeholder', count: 0),
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('pending store restores by ID without copying artifact bytes', () async {
    final factory = newDatabaseFactoryMemory();
    Future<Database> openDatabase() => factory.openDatabase('test');
    final store = PendingTextExportStore(openDatabase: openDatabase);
    final artifact = _artifact();
    final id = await store.put(artifact);
    final restored = await PendingTextExportStore(openDatabase: openDatabase)
        .get(id);
    expect(restored?.fileName, 'notes.txt');
    expect(restored?.bytes, utf8.encode('field\n'));
    expect(restored?.text, 'field\n');
    final boundedStore = PendingTextExportStore(
      openDatabase: openDatabase,
      maxArtifactBytes: 1,
    );
    await expectLater(
      boundedStore.put(artifact),
      throwsA(isA<PendingTextExportTooLargeException>()),
    );
    var openAttempts = 0;
    final retryableStore = PendingTextExportStore(
      openDatabase: () async {
        if (openAttempts++ == 0) throw StateError('temporary store failure');
        return openDatabase();
      },
    );
    await expectLater(retryableStore.put(artifact), throwsStateError);
    expect(await retryableStore.put(artifact), isNotEmpty);
    await store.remove(id);
    expect(await store.get(id), isNull);
  });

  test(
    'pending store prunes stale records and enforces aggregate size',
    () async {
      final factory = newDatabaseFactoryMemory();
      Future<Database> openDatabase() => factory.openDatabase('bounded');
      final database = await openDatabase();
      final records = stringMapStoreFactory.store('pending_text_exports');
      await records.record('stale').put(database, {
        'fileName': 'old.txt',
        'text': 'old',
        'createdAt': 0,
      });
      final store = PendingTextExportStore(
        openDatabase: openDatabase,
        maxPendingBytes: 7,
        maxPendingAge: const Duration(days: 1),
      );
      final id = await store.put(_artifact());
      expect(await records.record('stale').get(database), isNull);
      await expectLater(
        store.put(_artifact()),
        throwsA(isA<PendingTextExportStoreFullException>()),
      );
      expect((await store.get(id))?.text, 'field\n');
    },
  );

  test('concurrent pending writes cannot exceed the aggregate cap', () async {
    final factory = newDatabaseFactoryMemory();
    final store = PendingTextExportStore(
      openDatabase: () => factory.openDatabase('concurrent'),
      maxPendingBytes: 7,
    );
    Future<Object> put() async {
      try {
        return await store.put(_artifact());
      } on Object catch (error) {
        return error;
      }
    }

    final outcomes = await Future.wait([put(), put()]);
    expect(outcomes.whereType<String>(), hasLength(1));
    expect(
      outcomes.whereType<PendingTextExportStoreFullException>(),
      hasLength(1),
    );
  });

  test('Linux mail body size is bounded and points users to Save', () async {
    final delivery = PlatformTextExportDelivery(isLinux: () => true);
    final tooLarge = TextExportArtifact(
      fileName: 'cards.txt',
      bytes: Uint8List.fromList(List.filled(8193, 120)),
      text: List.filled(8193, 'x').join(),
    );
    await expectLater(
      delivery.share(tooLarge),
      throwsA(isA<TextExportShareTooLargeException>()),
    );
  });

  test(
    'FileSaver adapter receives the name, bytes, and MIME for Web download',
    () async {
      final writer = _FakeFileSaveAs()..result = 'Downloads';
      final delivery = PlatformTextExportDelivery(fileSaveAs: writer);
      final artifact = _artifact();

      expect(await delivery.save(artifact), isTrue);
      expect(writer.fileName, 'notes.txt');
      expect(writer.bytes, utf8.encode('field\n'));
      expect(writer.mimeType, 'text/plain');
      writer.result = null;
      expect(await delivery.save(artifact), isFalse);
    },
  );

  test(
    'Linux Share sends the export text through its supported mail intent',
    () async {
      ShareParams? sent;
      final delivery = PlatformTextExportDelivery(
        isLinux: () => true,
        shareRequest: (params) async {
          sent = params;
          return ShareResult.unavailable;
        },
      );

      expect(await delivery.share(_artifact()), isFalse);
      expect(sent?.files, isNull);
      expect(sent?.text, 'field\n');
      expect(sent?.subject, 'notes.txt');
    },
  );
}

DeckPickerExportDeckRequest _request(DeckPickerExportFormat format) =>
    projectDeckPickerExportDeck(
      legacyDeckId: 0,
      exactDeckId: Int64.parseInt('9007199254740995'),
      format: format,
      options: DeckPickerExportOptions.defaultsFor(format),
    );

TextExportArtifact _artifact() => TextExportArtifact(
  fileName: 'notes.txt',
  bytes: Uint8List.fromList(utf8.encode('field\n')),
  text: 'field\n',
);

Widget _app(TextExportArtifact artifact, TextExportDelivery delivery) =>
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
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) =>
                  TextExportReadyDialog(artifact: artifact, delivery: delivery),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

final class _FakeDelivery implements TextExportDelivery {
  TextExportArtifact? saved;
  TextExportArtifact? shared;
  bool nextSaveResult = true;
  Object? nextShareError;

  @override
  Future<bool> save(TextExportArtifact artifact) async {
    saved = artifact;
    return nextSaveResult;
  }

  @override
  Future<bool> share(TextExportArtifact artifact) async {
    shared = artifact;
    final error = nextShareError;
    nextShareError = null;
    if (error != null) throw error;
    return true;
  }
}

final class _FakeFileSaveAs implements TextFileSaveAs {
  String? result;
  String? fileName;
  List<int>? bytes;
  String? mimeType;

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    this.fileName = fileName;
    this.bytes = bytes;
    this.mimeType = mimeType;
    return result;
  }
}
