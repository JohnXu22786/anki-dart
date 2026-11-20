// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:web/web.dart' as web;

const _storeName = 'anki_media_v1';
const _readChunkBytes = 64 * 1024;

/// Opens a collection media store in its own IndexedDB database.
///
/// The database name is selected by the host and should be stable for the
/// collection. Media values are stored as Blobs so reads can be streamed in
/// bounded chunks without loading the complete object into a Dart byte array.
final class IndexedDbCollectionMediaStorage implements CollectionMediaStorage {
  IndexedDbCollectionMediaStorage._(this._database);

  final web.IDBDatabase _database;
  bool _closed = false;

  static Future<IndexedDbCollectionMediaStorage> open(
    String databaseName,
  ) async {
    if (databaseName.isEmpty || databaseName.length > 128) {
      throw ArgumentError.value(databaseName, 'databaseName');
    }
    final request = web.window.indexedDB.open(databaseName, 1);
    request.onupgradeneeded = ((web.Event _) {
      final database = request.result as web.IDBDatabase;
      if (!database.objectStoreNames.contains(_storeName)) {
        database.createObjectStore(_storeName);
      }
    }).toJS;
    final database = await _requestResult<web.IDBDatabase>(request);
    return IndexedDbCollectionMediaStorage._(database);
  }

  /// Opens a separate stable IndexedDB database associated with a collection.
  static Future<IndexedDbCollectionMediaStorage> openForCollection(
    String collectionDatabaseName,
  ) => open('$collectionDatabaseName-media');

  /// Stores a media object as a Blob under its validated Anki filename.
  Future<void> write(String filename, Uint8List bytes) async {
    final key = validateAnkiMediaFilename(filename);
    _ensureOpen();
    final transaction = _database.transaction(_storeName.toJS, 'readwrite');
    final completed = _transactionCompleted(transaction);
    final blob = web.Blob([bytes.toJS].toJS);
    final request = transaction.objectStore(_storeName).put(blob, key.toJS);
    await _requestAndTransaction<JSAny?>(request, completed);
  }

  @override
  Future<Stream<List<int>>?> read(String filename) async {
    final key = validateAnkiMediaFilename(filename);
    _ensureOpen();
    final transaction = _database.transaction(_storeName.toJS, 'readonly');
    final completed = _transactionCompleted(transaction);
    final result = await _requestAndTransaction<JSAny?>(
      transaction.objectStore(_storeName).get(key.toJS),
      completed,
    );
    if (result == null) return null;
    return _streamBlob(result as web.Blob);
  }

  @override
  Future<Iterable<String>> list() async {
    _ensureOpen();
    final transaction = _database.transaction(_storeName.toJS, 'readonly');
    final completed = _transactionCompleted(transaction);
    final result = await _requestAndTransaction<JSArray>(
      transaction.objectStore(_storeName).getAllKeys(),
      completed,
    );
    return result.toDart.map((key) => (key as JSString).toDart).toList();
  }

  /// Closes the IndexedDB connection. Reopen with [open] to access persisted
  /// objects again.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _database.close();
  }

  void _ensureOpen() {
    if (_closed) throw StateError('media storage is closed');
  }

  Stream<List<int>> _streamBlob(web.Blob blob) async* {
    for (var offset = 0; offset < blob.size; offset += _readChunkBytes) {
      final end = (offset + _readChunkBytes).clamp(0, blob.size);
      final buffer = await blob.slice(offset, end).arrayBuffer().toDart;
      yield Uint8List.fromList(buffer.toDart.asUint8List());
    }
  }
}

Future<T> _requestResult<T extends JSAny?>(web.IDBRequest request) {
  final completer = Completer<T>();
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(request.result as T);
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        request.error ?? StateError('IndexedDB request failed'),
      );
    }
  }).toJS;
  return completer.future;
}

Future<T> _requestAndTransaction<T extends JSAny?>(
  web.IDBRequest request,
  Future<void> completed,
) async {
  try {
    final value = await _requestResult<T>(request);
    await completed;
    return value;
  } catch (_) {
    try {
      await completed;
    } catch (_) {
      // Preserve the request or transaction error already being returned.
    }
    rethrow;
  }
}

Future<void> _transactionCompleted(web.IDBTransaction transaction) {
  final completer = Completer<void>();
  transaction.oncomplete = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  void fail(web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        transaction.error ?? StateError('IndexedDB transaction failed'),
      );
    }
  }

  transaction.onerror = fail.toJS;
  transaction.onabort = fail.toJS;
  return completer.future;
}
