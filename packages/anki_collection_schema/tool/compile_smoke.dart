// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';

import 'package:anki_collection_schema/anki_collection_schema.dart';

Future<void> main() async {
  if (collectionSchemaVersionStatus(18) !=
      CollectionSchemaVersionStatus.supported) {
    throw StateError('collection schema package JS smoke compilation failed');
  }

  final events = <String>[];
  final result = await openOrCreateCollection(
    _Database(events),
    _Callbacks(),
    serverMode: false,
  );
  if (result.created ||
      result.upgraded ||
      events.join(',') != 'exists,version') {
    throw StateError('collection open/create package JS smoke test failed');
  }
}

final class _Database implements CollectionOpenDatabase {
  _Database(this.events);

  final List<String> events;

  @override
  FutureOr<bool> queryExists(String sql) {
    events.add('exists');
    return true;
  }

  @override
  FutureOr<int> queryInt(String sql) {
    events.add('version');
    return 18;
  }

  @override
  FutureOr<String> queryString(String sql) => throw StateError('unexpected');

  @override
  FutureOr<void> beginExclusive() => throw StateError('unexpected');

  @override
  FutureOr<void> executeBatch(String sql) => throw StateError('unexpected');

  @override
  FutureOr<void> commit() => throw StateError('unexpected');

  @override
  FutureOr<void> rollback() => throw StateError('unexpected');
}

final class _Callbacks implements CollectionOpenCallbacks {
  @override
  FutureOr<void> initializeCollectionMetadata({required bool serverMode}) =>
      throw StateError('unexpected');

  @override
  FutureOr<void> addDefaultDeckConfig() => throw StateError('unexpected');

  @override
  FutureOr<void> addDefaultDeck() => throw StateError('unexpected');

  @override
  FutureOr<void> addStockNoteTypes() => throw StateError('unexpected');

  @override
  FutureOr<void> run(String name, {bool? serverMode}) =>
      throw StateError('unexpected');
}
