// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:convert';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/common.dart';

const _preparedStatementCacheCapacity = 50;

/// Opens a SQLite database for the caller-selected platform and location.
///
/// The driver owns platform-specific database configuration and can capture
/// any additional options in this callback. The adapter passes [location]
/// through unchanged and never removes or replaces an existing file.
final class CollectionSqliteDriver {
  const CollectionSqliteDriver({required this.openDatabase, this.flush});

  final FutureOr<CommonDatabase> Function(String location) openDatabase;

  /// Persists pending driver writes, when the platform has asynchronous
  /// storage such as the Web IndexedDB virtual file system.
  final FutureOr<void> Function()? flush;
}

/// SQLite connection settings aligned with Anki Core's collection opener.
final class CollectionSqliteOptions {
  const CollectionSqliteOptions({
    this.androidTempStore = false,
    this.configureConnection,
  });

  /// Android has no `/tmp` directory, so Anki Core stores temporary tables in
  /// memory there. The caller selects this from its platform entry point.
  final bool androidTempStore;

  /// Registers source-specific SQL functions and collations before the
  /// collection schema is inspected. Anki uses custom functions and the
  /// `unicase` collation that are outside this storage adapter's scope.
  final FutureOr<void> Function(CommonDatabase database)? configureConnection;
}

/// A concrete adapter for the source-compatible collection open sequence.
///
/// This configures SQLite before schema inspection with zero busy timeout,
/// exclusive locking, 4096-byte pages, a 40 MiB page cache, the source's
/// legacy-file-format setting, WAL, and a bounded cache for the hot exclusive
/// transaction statements. SQLite functions and collations used by the wider
/// Anki collection engine are not installed by this adapter.
final class CollectionSqliteStorage
    implements CollectionOpenDatabase, CollectionSchemaMigrationDatabase {
  CollectionSqliteStorage._(this._database, this._driver);

  final CommonDatabase _database;
  final CollectionSqliteDriver _driver;
  final Map<String, CommonPreparedStatement> _statementCache = {};
  bool _connectionClosed = false;
  bool _closed = false;

  /// Opens [location] through the chosen [driver] and applies collection
  /// connection pragmas before returning the database adapter.
  static Future<CollectionSqliteStorage> open({
    required CollectionSqliteDriver driver,
    required String location,
    CollectionSqliteOptions options = const CollectionSqliteOptions(),
  }) async {
    final database = await Future<CommonDatabase>.sync(
      () => driver.openDatabase(location),
    );
    try {
      database.execute('pragma busy_timeout = 0');
      database.execute('pragma locking_mode = exclusive');
      database.execute('pragma page_size = 4096');
      database.execute('pragma cache_size = -40960');
      database.execute('pragma legacy_file_format = off');
      database.execute('pragma journal_mode = wal');
      if (options.androidTempStore) {
        database.execute('pragma temp_store = memory');
      }
      final configureConnection = options.configureConnection;
      if (configureConnection != null) {
        await Future<void>.sync(() => configureConnection(database));
      }
      await Future<void>.sync(() => driver.flush?.call());
      return CollectionSqliteStorage._(database, driver);
    } catch (error, stackTrace) {
      try {
        database.close();
      } catch (_) {
        // Keep the initialization failure as the observable error.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<bool> queryExists(String sql) async =>
      _database.select(sql).isNotEmpty;

  @override
  Future<int> queryInt(String sql) async =>
      _database.select(sql).first.columnAt(0) as int;

  @override
  Future<String> queryString(String sql) async =>
      _database.select(sql).first.columnAt(0) as String;

  /// Returns a stored card, or null when no card has [id].
  Future<Card?> getCard(CardId id) async {
    final rows = _database.select(
      'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
      'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
      'flags, data FROM cards WHERE id = ?',
      [_toSqlInt64(id)],
    );
    return rows.isEmpty ? null : _cardFromRow(rows.first);
  }

  /// Returns all stored cards for [noteId], in SQLite's natural query order.
  Future<List<Card>> allCardsOfNote(NoteId noteId) async => _database
      .select(
        'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
        'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
        'flags, data FROM cards WHERE nid = ?',
        [_toSqlInt64(noteId)],
      )
      .map(_cardFromRow)
      .toList(growable: false);

  /// Returns card IDs ordered by their template ordinal for [noteId].
  Future<List<CardId>> allCardIdsOfNoteInTemplateOrder(NoteId noteId) async =>
      _database
          .select('SELECT id FROM cards WHERE nid = ? ORDER BY ord', [
            _toSqlInt64(noteId),
          ])
          .map((row) => _readInt64(row.columnAt(0)))
          .toList(growable: false);

  /// Returns a stored note, or null when no note has [noteId].
  Future<Note?> getNote(NoteId noteId) async {
    final rows = _database.select(
      'SELECT id, guid, mid, mod, usn, tags, flds, cast(sfld AS text), csum '
      'FROM notes WHERE id = ?',
      [_toSqlInt64(noteId)],
    );
    return rows.isEmpty ? null : _noteFromRow(rows.first);
  }

  /// Returns a stored note without loading its fields.
  Future<Note?> getNoteWithoutFields(NoteId noteId) async {
    final rows = _database.select(
      "SELECT id, guid, mid, mod, usn, tags, '', cast(sfld AS text), csum "
      'FROM notes WHERE id = ?',
      [_toSqlInt64(noteId)],
    );
    return rows.isEmpty ? null : _noteFromRow(rows.first);
  }

  /// Returns the set of IDs for all stored notes.
  Future<Set<NoteId>> getAllNoteIds() async => _database
      .select('SELECT id FROM notes')
      .map((row) => _readInt64(row.columnAt(0)))
      .toSet();

  @override
  Future<void> beginExclusive() async {
    _executeCached('begin exclusive');
  }

  @override
  Future<void> executeBatch(String sql) async {
    _database.execute(sql);
    if (_database.autocommit) await _flush();
  }

  @override
  Future<void> commit() async {
    if (_database.autocommit) return;
    _executeCached('commit');
    await _flush();
  }

  @override
  Future<void> rollback() async {
    if (_database.autocommit) return;
    _database.execute('rollback');
    await _flush();
  }

  /// Optionally downgrades the collection, flushes pending platform writes,
  /// and closes the connection once.
  ///
  /// [desiredVersion] supports 18 as a no-op and 11 as the catalogued schema
  /// downgrade followed by switching SQLite to delete journal mode. A schema
  /// 11 downgrade requires its host callbacks. Repeated calls are harmless.
  /// The collection file is never deleted.
  Future<void> close({
    int? desiredVersion,
    CollectionSchemaMigrationCallbacks? callbacks,
  }) async {
    if (_closed) return;
    Object? closeError;
    StackTrace? closeStack;

    try {
      if (desiredVersion != null) {
        if (desiredVersion != 11 && desiredVersion != 18) {
          throw ArgumentError.value(
            desiredVersion,
            'desiredVersion',
            'must be 11 or 18',
          );
        }
        if (desiredVersion == 11) {
          if (callbacks == null) {
            throw ArgumentError.notNull('callbacks');
          }
          await downgradeCollectionSchema(
            this,
            callbacks,
            toVersion: desiredVersion,
          );
          final journalMode = _database
              .select('pragma journal_mode = delete')
              .first
              .columnAt(0);
          if (journalMode != 'delete') {
            throw StateError('unable to switch journal mode to delete');
          }
        }
      }
    } catch (error, stackTrace) {
      closeError = error;
      closeStack = stackTrace;
    }

    for (final statement in _statementCache.values.toList()) {
      try {
        statement.close();
      } catch (error, stackTrace) {
        closeError ??= error;
        closeStack ??= stackTrace;
      }
    }
    _statementCache.clear();
    if (!_connectionClosed) {
      try {
        _database.close();
        _connectionClosed = true;
      } catch (error, stackTrace) {
        closeError ??= error;
        closeStack ??= stackTrace;
      }
    }
    try {
      await _flush();
    } catch (error, stackTrace) {
      closeError ??= error;
      closeStack ??= stackTrace;
    }
    if (_connectionClosed) _closed = true;
    if (closeError != null) {
      Error.throwWithStackTrace(closeError, closeStack!);
    }
  }

  /// Alias for [close] for callers using disposable-resource terminology.
  Future<void> dispose() => close();

  Future<void> _flush() async {
    await Future<void>.sync(() => _driver.flush?.call());
  }

  /// Flushes the WAL into the database and truncates it.
  ///
  /// Checkpointing requires an idle connection and surfaces SQLite's return
  /// code instead of treating a busy result as success.
  Future<void> checkpoint() async {
    if (!_database.autocommit) throw StateError('active transaction');
    final result = _database.select('pragma wal_checkpoint(truncate)');
    final returnCode = result.first.columnAt(0) as int;
    if (returnCode != 0) throw StateError('unable to checkpoint');
    await _flush();
  }

  /// Returns true when SQLite reports corruption or cannot run quick_check.
  Future<bool> quickCheckCorrupt() async {
    try {
      final result = _database.select('pragma quick_check');
      return result.first.columnAt(0) != 'ok';
    } catch (_) {
      return true;
    }
  }

  /// Runs Anki Core's database maintenance statements in source order.
  Future<void> optimize() async {
    await executeBatch('vacuum; reindex; analyze');
  }

  void _executeCached(String sql) {
    var statement = _statementCache[sql];
    if (statement == null) {
      statement = _database.prepare(sql, persistent: true);
      if (_statementCache.length >= _preparedStatementCacheCapacity) {
        final oldestSql = _statementCache.keys.first;
        _statementCache.remove(oldestSql)!.close();
      }
      _statementCache[sql] = statement;
    }
    statement.execute();
  }
}

Card _cardFromRow(Row row) {
  final data = _cardData(row.columnAt(17));
  final rawType = _castToUnsigned8(row.columnAt(6));
  final rawQueue = _castToSigned8(row.columnAt(7));
  return Card(
    id: _readInt64(row.columnAt(0)),
    noteId: _readInt64(row.columnAt(1)),
    deckId: _readInt64(row.columnAt(2)),
    templateIdx: _requiredUnsigned(row.columnAt(3), 16, 'ord'),
    mtimeSecs: _readInt64(row.columnAt(4)),
    usn: _requiredSigned(row.columnAt(5), 32, 'usn'),
    ctype: CardType.fromRaw(rawType),
    queue: CardQueue.fromRaw(rawQueue),
    due: _optionalInt32(row.columnAt(8)) ?? 0,
    interval: _requiredUnsigned(row.columnAt(9), 32, 'ivl'),
    easeFactorRaw: _requiredUnsigned(row.columnAt(10), 16, 'factor'),
    reps: _requiredUnsigned(row.columnAt(11), 32, 'reps'),
    lapses: _requiredUnsigned(row.columnAt(12), 32, 'lapses'),
    remainingStepsRaw: _requiredUnsigned(row.columnAt(13), 32, 'left'),
    originalDue: _optionalInt32(row.columnAt(14)) ?? 0,
    originalDeckId: _readInt64(row.columnAt(15)),
    flags: _requiredUnsigned(row.columnAt(16), 8, 'flags'),
    originalPosition: data.originalPosition,
    memoryState: data.memoryState,
    desiredRetention: data.desiredRetention,
    decay: data.decay,
    lastReviewTimeSecs: data.lastReviewTimeSecs,
    customData: data.customData,
  );
}

Note _noteFromRow(Row row) => Note(
  id: _readInt64(row.columnAt(0)),
  guid: row.columnAt(1) as String,
  notetypeId: _readInt64(row.columnAt(2)),
  mtimeSecs: _readInt64(row.columnAt(3)),
  usn: _requiredSigned(row.columnAt(4), 32, 'usn'),
  tags: _splitTags(row.columnAt(5) as String),
  fields: (row.columnAt(6) as String).split('\x1f'),
  sortField: row.columnAt(7) as String,
  checksum: _optionalUnsigned(row.columnAt(8), 32) ?? 0,
);

List<String> _splitTags(String tags) => tags
    .split(RegExp('[ \\u3000]'))
    .where((tag) => tag.isNotEmpty)
    .toList(growable: false);

_StoredCardData _cardData(Object? rawData) {
  if (rawData is! String) return const _StoredCardData();
  Object? decoded;
  try {
    decoded = jsonDecode(rawData);
  } on FormatException {
    return const _StoredCardData();
  }
  if (decoded is! Map<String, dynamic>) return const _StoredCardData();
  if (decoded.containsKey('cd') && decoded['cd'] is! String) {
    return const _StoredCardData();
  }

  final position = _optionalInt(decoded['pos']);
  final stability = _optionalFloat32(decoded['s']);
  final difficulty = _optionalFloat32(decoded['d']);
  return _StoredCardData(
    originalPosition: position == null ? null : position.toUnsigned(32),
    memoryState: stability == null || difficulty == null
        ? null
        : FsrsMemoryState(stability: stability, difficulty: difficulty),
    desiredRetention: _optionalFloat32(decoded['dr']),
    decay: _optionalFloat32(decoded['decay']),
    lastReviewTimeSecs: _optionalInt64(decoded['lrt']),
    customData: decoded['cd'] is String ? decoded['cd'] as String : '',
  );
}

Int64 _readInt64(Object? value) => switch (value) {
  int integer => Int64(integer),
  BigInt integer => Int64.parseInt(integer.toString()),
  _ => throw FormatException('Expected SQLite 64-bit integer, got $value'),
};

BigInt _toSqlInt64(Int64 value) => BigInt.parse(value.toString());

BigInt? _asBigInt(Object? value) => switch (value) {
  int integer => BigInt.from(integer),
  BigInt integer => integer,
  _ => null,
};

int _requiredUnsigned(Object? value, int bits, String field) {
  final integer = _optionalUnsigned(value, bits);
  if (integer == null) {
    throw FormatException('Invalid unsigned $bits-bit SQLite value for $field');
  }
  return integer;
}

int? _optionalUnsigned(Object? value, int bits) {
  final integer = _asBigInt(value);
  final maximum = (BigInt.one << bits) - BigInt.one;
  if (integer == null || integer < BigInt.zero || integer > maximum)
    return null;
  return integer.toInt();
}

int _requiredSigned(Object? value, int bits, String field) {
  final integer = _asBigInt(value);
  final minimum = -(BigInt.one << (bits - 1));
  final maximum = (BigInt.one << (bits - 1)) - BigInt.one;
  if (integer == null || integer < minimum || integer > maximum) {
    throw FormatException('Invalid signed $bits-bit SQLite value for $field');
  }
  return integer.toInt();
}

int _castToUnsigned8(Object? value) {
  final integer = _asBigInt(value);
  if (integer == null) throw const FormatException('Invalid SQLite card type');
  return (integer % BigInt.from(256)).toInt();
}

int _castToSigned8(Object? value) {
  final unsigned = _castToUnsigned8(value);
  return unsigned >= 128 ? unsigned - 256 : unsigned;
}

int? _optionalInt(Object? value) {
  if (value is int) return value >= 0 && value <= 0xffffffff ? value : null;
  if (value is BigInt &&
      value >= BigInt.zero &&
      value <= BigInt.from(0xffffffff)) {
    return value.toInt();
  }
  return null;
}

int? _optionalInt32(Object? value) {
  if (value is int) {
    return value >= -0x80000000 && value <= 0x7fffffff ? value : null;
  }
  if (value is BigInt &&
      value >= BigInt.from(-0x80000000) &&
      value <= BigInt.from(0x7fffffff)) {
    return value.toInt();
  }
  return null;
}

double? _optionalFloat32(Object? value) {
  final number = switch (value) {
    int integer => integer.toDouble(),
    double floatingPoint => floatingPoint,
    _ => null,
  };
  const maximum = 3.4028234663852886e38;
  if (number == null || number < -maximum || number > maximum) return null;
  return number;
}

Int64? _optionalInt64(Object? value) => switch (value) {
  int integer => _int64IfInRange(BigInt.from(integer)),
  BigInt integer => _int64IfInRange(integer),
  _ => null,
};

Int64? _int64IfInRange(BigInt integer) {
  if (integer < -(BigInt.one << 63) ||
      integer > (BigInt.one << 63) - BigInt.one) {
    return null;
  }
  return Int64.parseInt(integer.toString());
}

final class _StoredCardData {
  const _StoredCardData({
    this.originalPosition,
    this.memoryState,
    this.desiredRetention,
    this.decay,
    this.lastReviewTimeSecs,
    this.customData = '',
  });

  final int? originalPosition;
  final FsrsMemoryState? memoryState;
  final double? desiredRetention;
  final double? decay;
  final Int64? lastReviewTimeSecs;
  final String customData;
}
