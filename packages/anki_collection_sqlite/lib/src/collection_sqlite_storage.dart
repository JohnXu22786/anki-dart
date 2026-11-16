// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as protoConfig;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as protoNotetype;
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/common.dart';

import 'card_data_functions.dart';
import 'fnvhash.dart';
import 'fsrs_retrievability_functions.dart';
import 'fsrs_variable_function.dart';
import 'process_text.dart';
import 'regex_functions.dart';
import 'unicase_collation.dart';

part 'legacy_collection_migrations.dart';

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

  /// Registers additional source-specific SQL functions and collations before
  /// the collection schema is inspected. `field_at_index`, `process_text`,
  /// `fnvhash`, `extract_original_position`, `extract_custom_data`, and
  /// `extract_fsrs_variable`, both FSRS retrievability functions, `regexp`,
  /// `regexp_fields`, `regexp_tags`, and `unicase` are installed by default;
  /// remaining Core functions are host-provided.
  final FutureOr<void> Function(CommonDatabase database)? configureConnection;
}

/// A concrete adapter for the source-compatible collection open sequence.
///
/// This configures SQLite before schema inspection with zero busy timeout,
/// exclusive locking, 4096-byte pages, a 40 MiB page cache, the source's
/// legacy-file-format setting, WAL, and a bounded cache for the hot exclusive
/// transaction statements. Core's `field_at_index`, `process_text`,
/// `fnvhash`, card-data, FSRS, and regex extraction functions and `unicase`
/// collation are installed on every connection; other functions are not.
final class CollectionSqliteStorage
    implements CollectionOpenDatabase, CollectionSchemaMigrationDatabase {
  CollectionSqliteStorage._(this._database, this._driver);

  final CommonDatabase _database;
  final CollectionSqliteDriver _driver;
  final Map<String, CommonPreparedStatement> _statementCache = {};
  late final DeckStorage _deckStorage = DeckStorage(
    _DeckStorageDatabase(_database),
  );
  late final DeckConfigStorage _deckConfigStorage = DeckConfigStorage(
    _DeckStorageDatabase(_database),
  );
  late final TagStorage _tagStorage = TagStorage(
    _DeckStorageDatabase(_database),
  );
  late final RevlogStorage _revlogStorage = RevlogStorage(
    _DeckStorageDatabase(_database),
  );
  bool _connectionClosed = false;
  bool _closed = false;

  /// Returns source-compatible Deck row operations on this collection.
  DeckStorage get decks => _deckStorage;

  /// Returns source-compatible deck configuration row operations.
  DeckConfigStorage get deckConfigs => _deckConfigStorage;

  /// Returns source-compatible collection tag row operations.
  TagStorage get tags => _tagStorage;

  /// Returns source-compatible review log row operations on this collection.
  RevlogStorage get revlog => _revlogStorage;

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
      _registerCoreFieldIndexFunction(database);
      registerProcessTextFunction(database);
      registerFnvHashFunction(database);
      registerCardDataFunctions(database);
      registerFsrsVariableFunction(database);
      registerFsrsRetrievabilityFunctions(database);
      registerRegexFunctions(database);
      registerUnicaseCollation(database);
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

  /// Updates all persisted scheduling fields for [card].
  Future<void> updateCard(Card card) async {
    _database.execute('''
      UPDATE cards SET nid = ?, did = ?, ord = ?, mod = ?, usn = ?,
        type = ?, queue = ?, due = ?, ivl = ?, factor = ?, reps = ?,
        lapses = ?, left = ?, odue = ?, odid = ?, flags = ?, data = ?
      WHERE id = ?
    ''', _cardValues(card)..add(_toSqlInt64(card.id)));
    await _flushIfAutocommit();
  }

  /// Inserts [card], allocating a new row ID if the current time ID is taken.
  ///
  /// Returns the ID assigned by SQLite, including the source's collision
  /// allocation behavior. The shared [Card] model is immutable, so callers
  /// receive the assigned ID instead of having the model mutated in place.
  Future<CardId> addCard(Card card) async {
    final values = _cardValues(card);
    final now = DateTime.now().millisecondsSinceEpoch;
    final statement = _database.prepare('''
      INSERT INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (
        CASE WHEN ?1 IN (SELECT id FROM cards)
          THEN (SELECT max(id) + 1 FROM cards) ELSE ?1 END,
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
      )
    ''');
    late final CardId id;
    try {
      statement.execute([now, ...values]);
      id = _readInt64(
        _database
            .select('SELECT id FROM cards WHERE rowid = last_insert_rowid()')
            .single
            .columnAt(0),
      );
    } finally {
      statement.close();
    }
    await _flushIfAutocommit();
    return id;
  }

  /// Inserts [card] only when its ID is unused, returning whether a row was
  /// inserted. Constraints handled by SQLite's `OR IGNORE` policy return
  /// `false`; SQLite errors not handled by that policy are surfaced.
  Future<bool> addCardIfUnique(Card card) async {
    final values = _cardValues(card);
    final statement = _database.prepare('''
      INSERT OR IGNORE INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    late final bool inserted;
    try {
      statement.execute([_toSqlInt64(card.id), ...values]);
      inserted = _database.updatedRows == 1;
    } finally {
      statement.close();
    }
    await _flushIfAutocommit();
    return inserted;
  }

  /// Inserts or replaces [card] using its provided ID, as used by sync/undo.
  Future<void> addOrUpdateCard(Card card) async {
    _database.execute(
      '''
      INSERT OR REPLACE INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [_toSqlInt64(card.id), ..._cardValues(card)],
    );
    await _flushIfAutocommit();
  }

  /// Removes [id]. Deleting a missing row succeeds without a result.
  Future<void> removeCard(CardId id) async {
    _database.execute('DELETE FROM cards WHERE id = ?', [_toSqlInt64(id)]);
    await _flushIfAutocommit();
  }

  List<Object?> _cardValues(Card card) => [
    _toSqlInt64(card.noteId),
    _toSqlInt64(card.deckId),
    card.templateIdx,
    _toSqlInt64(card.mtimeSecs),
    card.usn,
    card.ctype.value,
    card.queue.value,
    card.due,
    card.interval,
    card.easeFactorRaw,
    card.reps,
    card.lapses,
    card.remainingStepsRaw,
    card.originalDue,
    _toSqlInt64(card.originalDeckId),
    card.flags,
    _cardDataJson(card),
  ];

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

  /// Writes the source schema-11 collection metadata for a newly-created file.
  Future<void> initializeMetadata({
    required bool serverMode,
    required DateTime now,
    required int Function(DateTime timestamp) localMinutesWest,
  }) async {
    final creation = _v1CreationDate(now, localMinutesWest(now));
    final creationDate = DateTime.fromMillisecondsSinceEpoch(
      creation * 1000,
      isUtc: true,
    ).toLocal();
    final creationOffset = serverMode ? null : localMinutesWest(creationDate);
    final config = <String, Object?>{
      'activeDecks': [1],
      'curDeck': 1,
      'newSpread': 0,
      'collapseTime': 1200,
      'timeLim': 0,
      'estTimes': true,
      'dueCounts': true,
      'curModel': null,
      'nextPos': 1,
      'sortType': 'noteFld',
      'sortBackwards': false,
      'addToCur': true,
      'dayLearnFirst': false,
      'schedVer': 2,
      'creationOffset': creationOffset,
      'sched2021': true,
    };
    _database.execute('UPDATE col SET crt = ?, scm = ?, ver = ?, conf = ?', [
      creation,
      now.millisecondsSinceEpoch,
      collectionSchemaStartingVersion,
      jsonEncode(config),
    ]);
    await _flushIfAutocommit();
  }

  /// Adds the pinned Core default deck configuration with its localized name.
  Future<void> addInitialDeckConfig(String name) async {
    final config = DeckConfig(
      id: Int64.ONE,
      name: name,
      inner: DeckConfig.defaults().inner,
    );
    _deckConfigStorage.addOrUpdateDeckConfigWithExistingId(config);
    await _flushIfAutocommit();
  }

  /// Adds the pinned Core default deck with its localized name.
  Future<void> addInitialDeck(String name) async {
    final deck = Deck(
      id: Int64.ONE,
      name: name,
      common: protoDeck.Deck_Common(
        studyCollapsed: true,
        browserCollapsed: true,
      ),
      kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
    );
    _deckStorage.addOrUpdateDeckWithExistingId(deck);
    await _flushIfAutocommit();
  }

  /// Persists Core's stock notetypes and sets the first as the current one.
  Future<void> addInitialStockNoteTypes({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
    required DateTime now,
  }) async {
    final notetypes = [
      StockNotetypeFactory.basic(names: names, randomU64: randomU64),
      StockNotetypeFactory.basicAndReversed(names: names, randomU64: randomU64),
      StockNotetypeFactory.basicOptionalReversed(
        names: names,
        randomU64: randomU64,
      ),
      StockNotetypeFactory.basicTyping(names: names, randomU64: randomU64),
      StockNotetypeFactory.cloze(names: names, randomU64: randomU64),
      StockNotetypeFactory.imageOcclusion(names: names, randomU64: randomU64),
    ];
    var firstId = Int64.ZERO;
    for (final notetype in notetypes) {
      notetype.normalizeNames();
      notetype.fixFieldNames();
      notetype.fixTemplateNames();
      notetype.ensureNamesUnique();
      notetype.config.reqs.addAll(_stockTemplateRequirements(notetype));
      final nowMillis = now.millisecondsSinceEpoch;
      final id = _readInt64(
        _database
            .select(
              'SELECT CASE WHEN ? IN (SELECT id FROM notetypes) THEN (SELECT max(id) + 1 FROM notetypes) ELSE ? END',
              [nowMillis, nowMillis],
            )
            .single
            .columnAt(0),
      );
      final config = notetype.config;
      _database.execute(
        'INSERT INTO notetypes (id, name, mtime_secs, usn, config) VALUES (?, ?, ?, ?, ?)',
        [
          _toSqlInt64(id),
          notetype.name,
          0,
          0,
          Uint8List.fromList(config.writeToBuffer()),
        ],
      );
      for (var index = 0; index < notetype.fields.length; index++) {
        final field = notetype.fields[index];
        _database.execute(
          'INSERT INTO fields (ntid, ord, name, config) VALUES (?, ?, ?, ?)',
          [
            _toSqlInt64(id),
            index,
            field.name,
            Uint8List.fromList(field.config.writeToBuffer()),
          ],
        );
      }
      for (var index = 0; index < notetype.templates.length; index++) {
        final template = notetype.templates[index];
        _database.execute(
          'INSERT INTO templates (ntid, ord, name, mtime_secs, usn, config) VALUES (?, ?, ?, ?, ?, ?)',
          [
            _toSqlInt64(id),
            index,
            template.name,
            0,
            0,
            Uint8List.fromList(template.config.writeToBuffer()),
          ],
        );
      }
      if (firstId == Int64.ZERO) firstId = id;
    }
    _database.execute(
      'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) VALUES (?, ?, ?, ?)',
      [
        'curModel',
        0,
        now.millisecondsSinceEpoch ~/ 1000,
        Uint8List.fromList(utf8.encode(firstId.toString())),
      ],
    );
    await _flushIfAutocommit();
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
    var flushFailed = false;

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
      flushFailed = true;
      closeError ??= error;
      closeStack ??= stackTrace;
    }
    if (_connectionClosed && !flushFailed) _closed = true;
    if (closeError != null) {
      Error.throwWithStackTrace(closeError, closeStack!);
    }
  }

  /// Alias for [close] for callers using disposable-resource terminology.
  Future<void> dispose() => close();

  Future<void> _flush() async {
    await Future<void>.sync(() => _driver.flush?.call());
  }

  Future<void> _flushIfAutocommit() async {
    if (_database.autocommit) await _flush();
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

final class _DeckStorageDatabase
    implements
        DeckStorageDatabase,
        DeckConfigStorageDatabase,
        TagStorageDatabase,
        RevlogStorageDatabase {
  const _DeckStorageDatabase(this.database);

  final CommonDatabase database;

  @override
  Int64 get lastInsertRowId => Int64(database.lastInsertRowId);

  @override
  List<Map<String, Object?>> select(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    final rows = database.select(sql, _sqliteParameters(parameters));
    final names = rows.columnNames;
    return rows
        .map(
          (row) => {
            for (var index = 0; index < names.length; index++)
              names[index]: row.columnAt(index),
          },
        )
        .toList(growable: false);
  }

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    database.execute(sql, _sqliteParameters(parameters));
    return database.updatedRows;
  }

  static List<Object?> _sqliteParameters(List<Object?> parameters) => parameters
      .map((value) => value is Int64 ? value.toString() : value)
      .toList(growable: false);
}

void _registerCoreFieldIndexFunction(CommonDatabase database) {
  database.createFunction(
    functionName: 'field_at_index',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    directOnly: false,
    function: (arguments) {
      final fields = arguments[0];
      if (fields is! String) {
        throw ArgumentError.value(
          fields,
          'fields',
          'must be stored field text',
        );
      }
      final index = arguments[1];
      if (index is! int || index < 0 || index > 0xffff) {
        throw RangeError('field_at_index index must fit Core u16');
      }
      final values = fields.split('\x1f');
      return index < values.length ? values[index] : '';
    },
  );
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

String _cardDataJson(Card card) {
  final data = <String>[];
  void add(String key, Object? value) =>
      data.add('${jsonEncode(key)}:${jsonEncode(value)}');
  void addFloat(String key, double value, int decimalPlaces) => data.add(
    '${jsonEncode(key)}:${_roundCardDataFloat(value, decimalPlaces)}',
  );

  if (card.originalPosition != null) add('pos', card.originalPosition);
  final memoryState = card.memoryState;
  if (memoryState != null) {
    addFloat('s', memoryState.stability, 4);
    addFloat('d', memoryState.difficulty, 3);
  }
  if (card.desiredRetention != null) {
    addFloat('dr', card.desiredRetention!, 2);
  }
  if (card.decay != null) addFloat('decay', card.decay!, 3);
  if (card.lastReviewTimeSecs != null) {
    data.add('"lrt":${card.lastReviewTimeSecs}');
  }
  if (card.customData.isNotEmpty && card.customData != '{}') {
    add('cd', card.customData);
  }
  return '{${data.join(',')}}';
}

String _roundCardDataFloat(double value, int decimalPlaces) {
  if (!value.isFinite) return 'null';
  final factor = switch (decimalPlaces) {
    2 => 100.0,
    3 => 1000.0,
    4 => 10000.0,
    _ => throw ArgumentError.value(decimalPlaces, 'decimalPlaces'),
  };
  final float32 = Float32List(1);
  float32[0] = value * factor;
  if (!float32[0].isFinite) return 'null';
  final rounded = float32[0].roundToDouble();
  float32[0] = rounded / factor;
  final roundedFloat = float32[0];
  for (var precision = 1; precision <= 9; precision++) {
    var shortest = roundedFloat.toStringAsPrecision(precision);
    float32[0] = double.parse(shortest);
    if (float32[0] == roundedFloat) {
      if (!shortest.contains('.') && !shortest.contains('e')) {
        shortest = '$shortest.0';
      }
      return _normalizeCardDataExponent(shortest);
    }
  }
  return roundedFloat.toString();
}

String _normalizeCardDataExponent(String value) {
  final exponentMarker = value.indexOf('e');
  if (exponentMarker == -1) return value;
  final exponent = int.parse(value.substring(exponentMarker + 1));
  if (exponent < 0 || exponent >= 16) return value.replaceFirst('e+', 'e');

  final mantissa = value.substring(0, exponentMarker);
  final sign = mantissa.startsWith('-') ? '-' : '';
  final decimalIndex = mantissa.indexOf('.');
  final digits = mantissa.replaceAll(RegExp(r'[.-]'), '');
  final integerDigits =
      (decimalIndex == -1 ? mantissa.length : decimalIndex) -
      sign.length +
      exponent;
  if (integerDigits >= digits.length) {
    return '$sign$digits${List.filled(integerDigits - digits.length, '0').join()}.0';
  }
  return '$sign${digits.substring(0, integerDigits)}.${digits.substring(integerDigits)}';
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

/// Localized values used while creating a new collection.
abstract interface class CollectionInitialTextProvider {
  String get defaultDeckName;

  StockNotetypeNames get stockNotetypeNames;
}

/// Source-compatible initial collection callbacks for [openOrCreateCollection].
///
/// Migration transformations remain supplied by the host until their separate
/// implementation unit is available. The callback uses the same storage
/// connection and transaction as schema creation.
final class CollectionSqliteInitializationCallbacks
    implements CollectionOpenCallbacks {
  const CollectionSqliteInitializationCallbacks({
    required this.storage,
    required this.text,
    required this.migrations,
    required this.localMinutesWest,
    required this.randomU64,
    this.clock = _now,
  });

  final CollectionSqliteStorage storage;
  final CollectionInitialTextProvider text;
  final CollectionSchemaMigrationCallbacks migrations;
  final int Function(DateTime timestamp) localMinutesWest;
  final BigInt Function() randomU64;
  final DateTime Function() clock;

  @override
  Future<void> initializeCollectionMetadata({required bool serverMode}) =>
      storage.initializeMetadata(
        serverMode: serverMode,
        now: clock(),
        localMinutesWest: localMinutesWest,
      );

  @override
  Future<void> addDefaultDeckConfig() =>
      storage.addInitialDeckConfig(text.defaultDeckName);

  @override
  Future<void> addDefaultDeck() => storage.addInitialDeck(text.defaultDeckName);

  @override
  Future<void> addStockNoteTypes() => storage.addInitialStockNoteTypes(
    names: text.stockNotetypeNames,
    randomU64: randomU64,
    now: clock(),
  );

  @override
  Future<void> run(String name, {bool? serverMode}) =>
      Future<void>.sync(() => migrations.run(name, serverMode: serverMode));
}

DateTime _now() => DateTime.now();

int _v1CreationDate(DateTime now, int minutesWest) {
  final localNowMillis =
      now.toUtc().millisecondsSinceEpoch -
      minutesWest * Duration.millisecondsPerMinute;
  final localNow = DateTime.fromMillisecondsSinceEpoch(
    localNowMillis,
    isUtc: true,
  );
  final fourAmLocalMillis = DateTime.utc(
    localNow.year,
    localNow.month,
    localNow.day,
    4,
  ).millisecondsSinceEpoch;
  final fourAmUtcMillis =
      fourAmLocalMillis + minutesWest * Duration.millisecondsPerMinute;
  final creationMillis = fourAmUtcMillis > now.toUtc().millisecondsSinceEpoch
      ? fourAmUtcMillis - Duration.millisecondsPerDay
      : fourAmUtcMillis;
  return creationMillis ~/ Duration.millisecondsPerSecond;
}

List<protoNotetype.Notetype_Config_CardRequirement> _stockTemplateRequirements(
  Notetype notetype,
) {
  final fieldOrdinals = <String, int>{
    for (var index = 0; index < notetype.fields.length; index++)
      notetype.fields[index].name: index,
  };
  return [
    for (var index = 0; index < notetype.templates.length; index++)
      _stockTemplateRequirement(
        index,
        _parseStockTemplate(notetype.templates[index].config.qFormat),
        fieldOrdinals,
      ),
  ];
}

protoNotetype.Notetype_Config_CardRequirement _stockTemplateRequirement(
  int cardOrdinal,
  List<_StockTemplateNode> nodes,
  Map<String, int> fieldOrdinals,
) {
  final fields = fieldOrdinals.keys.toList(growable: false);
  final any = <int>{};
  for (final field in fields) {
    if (_stockTemplateRenders(nodes, {field})) any.add(fieldOrdinals[field]!);
  }
  if (any.isNotEmpty) {
    return protoNotetype.Notetype_Config_CardRequirement(
      cardOrd: cardOrdinal,
      kind: protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_ANY,
      fieldOrds: any.toList()..sort(),
    );
  }

  final all = fieldOrdinals.values.toSet();
  for (final field in fields) {
    if (_stockTemplateRenders(
      nodes,
      fields.where((item) => item != field).toSet(),
    )) {
      all.remove(fieldOrdinals[field]);
    }
  }
  if (all.isNotEmpty && _stockTemplateRenders(nodes, fields.toSet())) {
    return protoNotetype.Notetype_Config_CardRequirement(
      cardOrd: cardOrdinal,
      kind: protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_ALL,
      fieldOrds: all.toList()..sort(),
    );
  }
  return protoNotetype.Notetype_Config_CardRequirement(
    cardOrd: cardOrdinal,
    kind: protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_NONE,
  );
}

bool _stockTemplateRenders(List<_StockTemplateNode> nodes, Set<String> fields) {
  for (final node in nodes) {
    switch (node) {
      case _StockTemplateField(:final name):
        if (fields.contains(name)) return true;
      case _StockTemplateSection(:final name, :final negated, :final children):
        if ((negated || fields.contains(name)) &&
            _stockTemplateRenders(children, fields)) {
          return true;
        }
    }
  }
  return false;
}

List<_StockTemplateNode> _parseStockTemplate(String source) {
  final roots = <_StockTemplateNode>[];
  final stack = <List<_StockTemplateNode>>[roots];
  final sections = <_StockTemplateSection>[];
  for (final match in RegExp(
    r'\{\{(.*?)\}\}',
    dotAll: true,
  ).allMatches(source)) {
    final tag = match.group(1)!.trim();
    if (tag.isEmpty) continue;
    final marker = tag[0];
    final body = tag.substring(1).trim();
    if (marker == '!') continue;
    if (marker == '# ' || marker == '^ ') continue;
    if (marker == '#' || marker == '^') {
      final name = _templateFieldName(body);
      final section = _StockTemplateSection(name, marker == '^');
      stack.last.add(section);
      sections.add(section);
      stack.add(section.children);
    } else if (marker == '/') {
      if (stack.length > 1) {
        stack.removeLast();
        sections.removeLast();
      }
    } else if (marker == '>') {
      continue;
    } else {
      final name = _templateFieldName(tag);
      stack.last.add(_StockTemplateField(name));
    }
  }
  return roots;
}

String _templateFieldName(String value) {
  final colon = value.lastIndexOf(':');
  return (colon < 0 ? value : value.substring(colon + 1)).trim();
}

sealed class _StockTemplateNode {}

final class _StockTemplateField extends _StockTemplateNode {
  _StockTemplateField(this.name);

  final String name;
}

final class _StockTemplateSection extends _StockTemplateNode {
  _StockTemplateSection(this.name, this.negated);

  final String name;
  final bool negated;
  final List<_StockTemplateNode> children = [];
}
