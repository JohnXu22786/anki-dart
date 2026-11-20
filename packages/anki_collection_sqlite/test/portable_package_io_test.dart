// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test(
    'native snapshot is reopenable and independent of later writes',
    () async {
      final sqlite = sqlite3;
      late Database live;
      final driver = nativeCollectionSqliteDriver(engine: sqlite);
      var deferNextFlush = false;
      final flushStarted = Completer<void>();
      final finishFlush = Completer<void>();
      final storage = await CollectionSqliteStorage.open(
        driver: CollectionSqliteDriver(
          openDatabase: (_) => live = sqlite.openInMemory(),
          flush: () {
            if (deferNextFlush) {
              deferNextFlush = false;
              flushStarted.complete();
              return finishFlush.future;
            }
          },
          snapshot: driver.snapshot,
        ),
        location: ':memory:',
      );
      final directory = await Directory.systemTemp.createTemp(
        'anki-snapshot-test-',
      );
      try {
        live.execute('CREATE TABLE sample(value TEXT)');
        live.execute("INSERT INTO sample VALUES ('before')");
        live.execute('BEGIN');
        await expectLater(storage.createSnapshot(), throwsStateError);
        live.execute('ROLLBACK');
        deferNextFlush = true;
        final snapshotDuringFlush = storage.createSnapshot();
        await flushStarted.future;
        live.execute('BEGIN');
        finishFlush.complete();
        await expectLater(snapshotDuringFlush, throwsStateError);
        live.execute('ROLLBACK');
        final bytes = await storage.createSnapshot();
        expect(await storage.createSnapshot(), bytes);
        expect(bytes, isNotEmpty);
        live.execute("UPDATE sample SET value = 'after'");
        final path = '${directory.path}${Platform.pathSeparator}snapshot.db';
        await File(path).writeAsBytes(bytes);
        final reopened = sqlite.open(path);
        addTearDown(reopened.close);
        expect(
          reopened.select('SELECT value FROM sample').single['value'],
          'before',
        );
        expect(
          live.select('SELECT value FROM sample').single['value'],
          'after',
        );
      } finally {
        await storage.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('media names reject traversal while allowing Unicode filenames', () {
    expect(validateAnkiMediaFilename('音声-ä.mp3'), '音声-ä.mp3');
    for (final invalid in [
      '',
      '..',
      '../collection.anki2',
      r'..\secret',
      'a/b',
      List.filled(1025, 'x').join(),
    ]) {
      expect(() => validateAnkiMediaFilename(invalid), throwsArgumentError);
    }
  });

  test(
    'media adapter returns bytes and missing items without path access',
    () async {
      final media = _MemoryMedia({
        '音声.mp3': Uint8List.fromList([1, 2, 3]),
      });
      final stream = await media.read(validateAnkiMediaFilename('音声.mp3'));
      expect(await stream!.expand((chunk) => chunk).toList(), [1, 2, 3]);
      expect(
        await media.read(validateAnkiMediaFilename('missing.mp3')),
        isNull,
      );
      expect(await media.list(), ['音声.mp3']);
    },
  );

  test('native directory media reads flat Unicode files', () async {
    final directory = await Directory.systemTemp.createTemp('anki-media-test-');
    try {
      await File(
        '${directory.path}${Platform.pathSeparator}音声.mp3',
      ).writeAsBytes([4, 5]);
      final media = DirectoryCollectionMediaStorage(directory);
      final stream = await media.read('音声.mp3');
      expect(await stream!.expand((chunk) => chunk).toList(), [4, 5]);
      expect(await media.read('absent.mp3'), isNull);
      expect(await media.list(), ['音声.mp3']);
      await expectLater(media.read('../secret'), throwsArgumentError);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

final class _MemoryMedia implements CollectionMediaStorage {
  _MemoryMedia(this.files);
  final Map<String, Uint8List> files;

  @override
  Future<void> close() async {}

  @override
  Future<Iterable<String>> list() async => files.keys;

  @override
  Future<Stream<List<int>>?> read(String filename) async {
    final bytes = files[filename];
    return bytes == null ? null : Stream.value(bytes);
  }
}
