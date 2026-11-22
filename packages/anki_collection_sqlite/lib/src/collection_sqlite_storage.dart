// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as protoConfig;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as protoNotetype;
import 'package:anki_backend_protocol/anki/collection.pb.dart'
    as protoCollection;
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:anki_search_parser/anki_search_parser.dart' as searchParser;
import 'package:fixnum/fixnum.dart';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:protobuf/protobuf.dart';
import 'package:sqlite3/common.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'card_data_functions.dart';
import 'fnvhash.dart';
import 'fsrs_retrievability_functions.dart';
import 'fsrs_variable_function.dart';
import 'process_text.dart';
import 'regex_functions.dart';
import 'search_executor.dart';
import 'unicase_collation.dart';
import 'deck_tree.dart';
import 'note_update.dart';
import 'core_random_position.dart';
import 'add_note.dart';
import 'text_export.dart';
import 'portable_package_io.dart';
import 'intraday_learning_candidate.dart';
import 'apkg_package_builder.dart';
import 'apkg_exporter.dart';

part 'legacy_collection_migrations.dart';
part 'apkg_export_operation.dart';
part 'database_check.dart';

const _preparedStatementCacheCapacity = 50;
final _collectionUndoOperationZoneKey = Object();
final _externalCollectionMutationZoneKey = Object();

/// Today's new/review queue counts and extension increments for custom study.
final class CollectionCustomStudyLimitDefaults {
  const CollectionCustomStudyLimitDefaults({
    required this.extendNew,
    required this.extendReview,
    required this.availableNew,
    required this.availableReview,
    required this.availableNewInChildren,
    required this.availableReviewInChildren,
  });
  final int extendNew, extendReview, availableNew, availableReview;
  final int availableNewInChildren, availableReviewInChildren;
}

/// Opens a SQLite database for the caller-selected platform and location.
///
/// The driver owns platform-specific database configuration and can capture
/// any additional options in this callback. The adapter passes [location]
/// through unchanged and never removes or replaces an existing file.
final class CollectionSqliteDriver {
  const CollectionSqliteDriver({
    required this.openDatabase,
    this.flush,
    this.snapshot,
    this.exportFromSnapshot,
    this.mediaStorage,
  });

  final FutureOr<CommonDatabase> Function(String location) openDatabase;

  /// Persists pending driver writes, when the platform has asynchronous
  /// storage such as the Web IndexedDB virtual file system.
  final FutureOr<void> Function()? flush;

  /// Creates a consistent byte snapshot without closing the live database.
  final Future<Uint8List> Function(CommonDatabase database)? snapshot;

  /// Clones [source] into an independent SQLite connection and runs [build]
  /// against that copy. Implementations must discard the copy after [build],
  /// including when it throws.
  final Future<Uint8List> Function(
    CommonDatabase source,
    Future<Uint8List> Function(CommonDatabase copy) build,
  )?
  exportFromSnapshot;

  /// Optional platform-owned collection media store.
  final CollectionMediaStorage? mediaStorage;
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

/// Collection row category represented by a Core-transaction SQLite change.
enum CollectionUndoChangeKind {
  card,
  note,
  noteTags,
  deck,
  deckConfig,
  tag,
  revlog,
  queue,
  config,
  collection,
  notetype,
  custom,
}

/// The source-derived mutation represented by a typed collection change.
enum CollectionUndoChangeVariant {
  added,
  updated,
  removed,
  graveAdded,
  graveRemoved,
  tagsUpdated,
  cardAnswered,
  cardAnswerUndone,
  modified,
  schemaModified,
  custom,
}

/// A supported collection operation. Names are stable localization keys for
/// host UI code and mirror the operation identity kept by the journal.
enum CollectionUndoOperation {
  updateNote,
  deleteCards,
  suspendCards,
  buryCards,
  unburyCards,
  deleteDeck,
  emptyFilteredDeck,
  buildFilteredDeck,
  extendStudyLimits,
  changeDeckDescription,
  changeDeckDailyLimits,
  createDeck,
  renameDeck,
  custom,
}

/// Typed row-level inverse metadata captured for a collection transaction.
final class CollectionUndoChange {
  const CollectionUndoChange({
    required this.kind,
    required this.variant,
    required this.table,
    required this.columns,
    required this.operation,
    required this.before,
    required this.after,
  });

  factory CollectionUndoChange.graveAdded({
    required CollectionUndoChangeKind kind,
    required Int64 objectId,
    required int graveType,
  }) => CollectionUndoChange(
    kind: kind,
    variant: CollectionUndoChangeVariant.graveAdded,
    table: 'graves',
    columns: const ['oid', 'type', 'usn'],
    operation: SqliteUpdateKind.insert,
    before: null,
    after: [objectId, graveType, -1],
  );

  final CollectionUndoChangeKind kind;
  final CollectionUndoChangeVariant variant;
  final String table;
  final List<String> columns;
  final SqliteUpdateKind operation;
  final List<Object?>? before;
  final List<Object?>? after;
}

/// Name and deleted-card count returned by a collection deck removal.
final class DeckRemovalResult {
  const DeckRemovalResult({
    required this.deckName,
    required this.cardsDeleted,
    required this.collectionUndoGeneration,
    this.persistenceWarning = false,
  });

  final String deckName;
  final int cardsDeleted;
  final int collectionUndoGeneration;
  final bool persistenceWarning;
}

/// Number of cards restored by a collection-backed deck unbury operation.
final class DeckUnburyResult {
  const DeckUnburyResult({
    required this.deckName,
    required this.cardsUnburied,
    required this.collectionUndoGeneration,
    this.persistenceWarning = false,
  });

  final String deckName;
  final int cardsUnburied;
  final int collectionUndoGeneration;
  final bool persistenceWarning;
}

/// Number of cards returned by a collection-backed filtered-deck empty.
final class FilteredDeckEmptyResult {
  const FilteredDeckEmptyResult({
    required this.deckName,
    required this.cardsReturned,
    required this.collectionUndoGeneration,
    this.persistenceWarning = false,
  });

  final String deckName;
  final int cardsReturned;
  final int collectionUndoGeneration;
  final bool persistenceWarning;
}

/// Result of creating or rebuilding a filtered deck in the collection.
final class FilteredDeckBuildResult {
  const FilteredDeckBuildResult({
    required this.deckId,
    required this.cardsMoved,
  });

  final Int64 deckId;
  final int cardsMoved;
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
  CollectionSqliteStorage._(
    this._database,
    this._driver,
    this._nowMillis,
    this._options,
  );

  final CommonDatabase _database;
  final CollectionSqliteDriver _driver;
  final int Function()? _nowMillis;
  final CollectionSqliteOptions _options;
  final Map<String, CommonPreparedStatement> _statementCache = {};
  Future<void> _searchQueue = Future<void>.value();
  Future<void> _existingNoteUpdateQueue = Future<void>.value();
  final List<_CollectionUndoStep> _collectionUndoSteps = [];
  final List<_CollectionUndoStep> _collectionRedoSteps = [];
  int _noteUpdateUndoCounter = 0;
  int _collectionUndoStepCounter = 0;
  int _collectionUndoExternalMutationGeneration = 0;
  int _collectionUndoGeneration = 0;
  int _collectionUndoLastEntryGeneration = -1;
  Completer<void>? _collectionUndoOperationDone;
  Completer<void>? _portableSnapshotDone;
  bool _portableSnapshotStarting = false;
  late final DeckStorage _deckStorage = DeckStorage(
    _DeckStorageDatabase(this, _invalidateOperationHistoryAfterSubstoreWrite),
  );
  late final DeckConfigStorage _deckConfigStorage = DeckConfigStorage(
    _DeckStorageDatabase(this, _invalidateOperationHistoryAfterSubstoreWrite),
  );
  late final TagStorage _tagStorage = TagStorage(
    _DeckStorageDatabase(this, _invalidateOperationHistoryAfterSubstoreWrite),
  );
  late final NoteStorage _noteStorage = NoteStorage(
    _CollectionNoteStorageDatabase(this),
    nowMillis: _nowMillis,
  );
  late final RevlogStorage _revlogStorage = RevlogStorage(
    _DeckStorageDatabase(this, _invalidateOperationHistoryAfterSubstoreWrite),
  );
  bool _connectionClosed = false;
  bool _closed = false;
  bool _mediaStorageClosed = false;
  bool _closing = false;

  /// Executes a compiled Core-compatible search and sort plan against this
  /// collection. Sort preparation and the final ID query share this connection.
  Future<List<BigInt>> executeSearchPlan(CompiledSearchSqlWithSort plan) {
    if (_closing || _connectionClosed || _closed) {
      return Future.error(StateError('collection storage is closing'));
    }
    final result = _searchQueue.then(
      (_) =>
          executeSearchSqlPlan(CollectionSqliteSearchExecutor(_database), plan),
    );
    _searchQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  /// Returns whether a Core search matches at least one card in this
  /// collection. This uses the same parser, timing context and SQL compiler as
  /// filtered-deck construction, while limiting work to one result.
  Future<bool> hasCardsMatchingSearch(String search) async {
    final nodes = searchParser.parse(search);
    final node = nodes.length == 1
        ? nodes.single
        : searchParser.GroupNode(nodes);
    final plan = compileSearchSqlWithSort(
      node,
      timing: _filteredSearchTiming(),
      sortOrder: SearchSqlSortOrder.custom('c.id limit 1'),
    );
    return (await executeSearchPlan(plan)).isNotEmpty;
  }

  /// Reads a JSON value from the collection config table.
  Object? readCollectionConfig(String key) {
    final rows = _database.select('SELECT val FROM config WHERE key = ?', [
      key,
    ]);
    if (rows.isEmpty) return null;
    return _decodeJsonValue(rows.single['val']);
  }

  /// Reads an integer config value without routing it through a JS number.
  Int64? readCollectionConfigInt64(String key) => _readConfigInt64(key);

  ExistingNoteUpdateConfigSnapshot? _readExistingNoteUpdateConfigSnapshot(
    String key,
  ) {
    final rows = _database.select(
      'SELECT key AS config_key, usn, mtime_secs, val FROM config WHERE key = ?',
      [key],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return ExistingNoteUpdateConfigSnapshot(
      key: row['config_key'] as String,
      usn: (row['usn'] as num).toInt(),
      mtimeSecs: _readInt64(row['mtime_secs']),
      value: row['val'] as List<int>,
    );
  }

  void _restoreExistingNoteUpdateConfigSnapshot(
    ExistingNoteUpdateConfigSnapshot? snapshot,
  ) {
    if (snapshot == null) {
      _database.execute('DELETE FROM config WHERE key = ?', ['nextPos']);
      return;
    }
    _database.execute(
      'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) '
      'VALUES (?, ?, ?, ?)',
      [
        snapshot.key,
        snapshot.usn,
        _toSqlInt64(snapshot.mtimeSecs),
        snapshot.value,
      ],
    );
  }

  /// Writes one JSON value to the collection config table and flushes it.
  Future<void> writeCollectionConfig(String key, Object value) =>
      _writeConfigValue(key, jsonEncode(value));

  /// Writes an integer config value without losing precision above 2^53.
  Future<void> writeCollectionConfigInt64(String key, Int64 value) =>
      _writeConfigValue(key, value.toString());

  /// Returns source-compatible Deck row operations on this collection.
  DeckStorage get decks => _deckStorage;

  /// Returns source-compatible deck configuration row operations.
  DeckConfigStorage get deckConfigs => _deckConfigStorage;

  /// Returns source-compatible collection tag row operations.
  TagStorage get tags => _tagStorage;

  /// Updates a note after its derived fields have been prepared.
  Future<void> updateNote(Note note) async {
    await _withExternalCollectionMutation(() => _noteStorage.updateNote(note));
    await _flushIfAutocommit();
  }

  /// Updates an existing note with Anki Core's editor-save behavior.
  ///
  /// The operation compares semantic content before preparing fields, keeps
  /// the stored timestamp on no-op detection, resolves the stored notetype and
  /// normalization setting, and adds any newly required cards in the same
  /// savepoint as the note update. Existing cards are left untouched. The
  /// returned undo record contains Core's old-note snapshot, and this storage
  /// records its inverse in the same bounded collection journal used by
  /// callback-backed collection operations.
  Future<ExistingNoteUpdateResult> updateExistingNote(Note edited) =>
      _serializeNoteUpdate(() async {
        final operationDone = await _acquireCollectionUndoOperation();
        _collectionUndoStepCounter++;
        Session? session;
        try {
          session = _createCollectionUndoSession();
          final operationTimeMillis =
              _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
          final historyGenerationAtStart =
              _collectionUndoExternalMutationGeneration;
          final result = await runZoned(
            () => _updateExistingNote(
              edited,
              operationTimeMillis: operationTimeMillis,
            ),
            zoneValues: {_collectionUndoOperationZoneKey: this},
          );
          if (result.changed) {
            final typedChanges = _collectionUndoChangesFromChangeset(
              session.changeset(),
            );
            _noteUpdateUndoCounter++;
            final record = result.undoRecord!;
            final afterMillis = _readInt64(
              _database.select('SELECT mod FROM col').single['mod'],
            );
            final step = _ExistingNoteUpdateUndoStep(
              before: record.oldNote,
              after: result.note,
              addedCards: result.addedCards,
              addedTags: record.addedTags,
              collectionMtimeBefore: record.collectionMtimeMillis,
              collectionMtimeAfter: afterMillis,
              nextCardPositionConfigBefore: record.nextCardPositionConfigBefore,
              nextCardPositionConfigAfter: record.nextCardPositionConfigAfter,
              operationTimestampSecs: operationTimeMillis ~/ 1000,
            );
            if (_collectionUndoExternalMutationGeneration !=
                historyGenerationAtStart) {
              return result;
            }
            final coalesceTimeSecs =
                (_nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch) ~/
                1000;
            final prior = _collectionUndoSteps.isEmpty
                ? null
                : _collectionUndoSteps.last;
            _collectionRedoSteps.clear();
            if (prior?.noteUpdate?.canCoalesceWith(
                  step,
                  coalesceTimeSecs: coalesceTimeSecs,
                ) ??
                false) {
              final merged = prior!.noteUpdate!.coalesceAfter(step);
              final mergedChanges = _mergeCollectionUndoChanges(
                prior.changes.toList(),
                typedChanges,
              );
              _collectionUndoSteps[_collectionUndoSteps.length -
                  1] = _noteUpdateJournalStep(
                merged,
                counter: prior.counter,
                changes: mergedChanges,
              );
            } else {
              _collectionUndoSteps.add(
                _noteUpdateJournalStep(step, changes: typedChanges),
              );
              if (_collectionUndoSteps.length > 30) {
                _collectionUndoSteps.removeAt(0);
              }
            }
            _collectionUndoGeneration++;
            _collectionUndoLastEntryGeneration = _collectionUndoGeneration;
            await _flushIfAutocommit(preserveNoteUpdateHistory: true);
          } else if (_collectionRedoSteps.isNotEmpty) {
            // Core starts a normal undoable step before it knows whether the
            // operation changes anything, so even a semantic no-op invalidates
            // redo history.
            _collectionRedoSteps.clear();
            _collectionUndoGeneration++;
          }
          return result;
        } finally {
          session?.delete();
          _releaseCollectionUndoOperation(operationDone);
        }
      });

  /// Compatibility view for the most recent note update in the shared journal.
  ExistingNoteUpdateUndoStatus get existingNoteUpdateUndoStatus =>
      ExistingNoteUpdateUndoStatus(
        canUndo:
            _collectionUndoSteps.isNotEmpty &&
            _collectionUndoSteps.last.noteUpdate != null,
        canRedo:
            _collectionRedoSteps.isNotEmpty &&
            _collectionRedoSteps.last.noteUpdate != null,
        lastStep: _noteUpdateUndoCounter,
      );

  _CollectionUndoStep _noteUpdateJournalStep(
    _ExistingNoteUpdateUndoStep step, {
    int? counter,
    List<CollectionUndoChange> changes = const [],
  }) => _CollectionUndoStep(
    label: CollectionUndoOperation.updateNote.name,
    counter: counter ?? _collectionUndoStepCounter,
    noteUpdate: step,
    actions: [
      _CollectionUndoAction(
        undo: () async => _applyExistingNoteUpdateUndoStep(step, undo: true),
        redo: () async => _applyExistingNoteUpdateUndoStep(step, undo: false),
        changes: changes,
      ),
    ],
  );

  /// Invalidates the scoped history after direct substore writes or a caller
  /// transaction that changes collection state outside this adapter.
  void discardExistingNoteUpdateUndoHistory() {
    if (identical(Zone.current[_collectionUndoOperationZoneKey], this)) return;
    _collectionUndoExternalMutationGeneration++;
    _collectionUndoSteps.clear();
    _collectionRedoSteps.clear();
    _collectionUndoGeneration++;
  }

  void _invalidateOperationHistoryAfterSubstoreWrite() {
    discardExistingNoteUpdateUndoHistory();
  }

  /// Reverts the latest successful [updateExistingNote] operation.
  Future<void> undoLastExistingNoteUpdate() => _serializeNoteUpdate(() async {
    if (_collectionUndoSteps.isEmpty ||
        _collectionUndoSteps.last.noteUpdate == null) {
      throw StateError('no existing-note update to undo');
    }
    await undoLastCollectionOperation();
  });

  /// Reapplies the latest undone [updateExistingNote] operation.
  Future<void> redoLastExistingNoteUpdate() => _serializeNoteUpdate(() async {
    if (_collectionRedoSteps.isEmpty ||
        _collectionRedoSteps.last.noteUpdate == null) {
      throw StateError('no existing-note update to redo');
    }
    await redoLastCollectionOperation();
  });

  Future<T> _withExternalCollectionMutation<T>(
    FutureOr<T> Function() mutation,
  ) async {
    if (identical(Zone.current[_collectionUndoOperationZoneKey], this) ||
        identical(Zone.current[_externalCollectionMutationZoneKey], this)) {
      return await mutation();
    }
    final operationDone = await _acquireCollectionUndoOperation();
    try {
      return await runZoned(
        () async => await mutation(),
        zoneValues: {_externalCollectionMutationZoneKey: this},
      );
    } finally {
      _releaseCollectionUndoOperation(operationDone);
    }
  }

  Future<T> _serializeNoteUpdate<T>(Future<T> Function() operation) {
    final result = _existingNoteUpdateQueue.then((_) => operation());
    _existingNoteUpdateQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  void _applyExistingNoteUpdateUndoStep(
    _ExistingNoteUpdateUndoStep step, {
    required bool undo,
  }) {
    if (_closing || _connectionClosed || _closed) {
      throw StateError('collection storage is closing');
    }
    _database.execute('SAVEPOINT core_note_update_undo');
    try {
      if (undo) {
        for (final card in step.addedCards.reversed) {
          _database.execute('DELETE FROM cards WHERE id = ?', [
            _toSqlInt64(card.id),
          ]);
        }
        _noteStorage.updateNote(copyNote(step.before));
        for (final tag in step.addedTags.reversed) {
          _tagStorage.removeSingleTag(tag);
        }
        _restoreExistingNoteUpdateConfigSnapshot(
          step.nextCardPositionConfigBefore,
        );
        _database.execute('UPDATE col SET mod = ?', [
          _toSqlInt64(step.collectionMtimeBefore),
        ]);
      } else {
        _noteStorage.updateNote(copyNote(step.after));
        for (final tag in step.addedTags) {
          _database.execute(
            'INSERT OR IGNORE INTO tags (tag, usn, collapsed) VALUES (?, -1, 1)',
            [tag],
          );
        }
        for (final card in step.addedCards) {
          _database.execute(
            '''
INSERT OR REPLACE INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
  lapses, left, odue, odid, flags, data
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
            [_toSqlInt64(card.id), ..._cardValues(card)],
          );
        }
        _restoreExistingNoteUpdateConfigSnapshot(
          step.nextCardPositionConfigAfter,
        );
        _database.execute('UPDATE col SET mod = ?', [
          _toSqlInt64(step.collectionMtimeAfter),
        ]);
      }
      _database.execute('RELEASE core_note_update_undo');
    } catch (error, stackTrace) {
      try {
        _database.execute('ROLLBACK TO core_note_update_undo');
        _database.execute('RELEASE core_note_update_undo');
      } catch (_) {
        // Preserve the original failure.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<ExistingNoteUpdateResult> _updateExistingNote(
    Note edited, {
    required int operationTimeMillis,
  }) async {
    if (_closing || _connectionClosed || _closed) {
      throw StateError('collection storage is closing');
    }
    final original = await getNote(edited.id);
    if (original == null) throw StateError('note not found: ${edited.id}');

    // Core's note_differs_from_db ignores stored derived values and trusts
    // the persisted mtime over a stale editor copy.
    final candidate = copyNote(edited)
      ..mtimeSecs = original.mtimeSecs
      ..fieldsMut();
    edited.mtimeSecs = original.mtimeSecs;
    if (!_semanticNoteDiffers(original, candidate)) {
      return ExistingNoteUpdateResult(
        changed: false,
        note: edited,
        addedCards: const [],
      );
    }

    final notetypes = await getNotetypesByIds([NotetypeId(edited.notetypeId)]);
    if (notetypes.isEmpty) {
      throw StateError('edited note type not found: ${edited.notetypeId}');
    }
    final notetype = notetypes.single;
    final existingCards = await allCardsOfNote(edited.id);
    final normalizeText = _normalizeNoteText;
    final nextPositionConfigBefore = _readExistingNoteUpdateConfigSnapshot(
      'nextPos',
    );
    final collectionMtimeMillis = _readInt64(
      _database.select('SELECT mod FROM col').single['mod'],
    );
    final modifiedAtMillis = operationTimeMillis;

    // No await occurs inside this savepoint. The update queue prevents stale
    // concurrent editor saves, and synchronous row writes cannot interleave
    // with other storage calls before release.
    _database.execute('SAVEPOINT core_update_existing_note');
    late final ExistingNoteUpdateResult result;
    try {
      final addedTags = _canonifyEditedTags(edited);
      edited.prepareForUpdate(notetype, normalizeText: normalizeText);
      edited.markModified(-1, mtimeSecs: modifiedAtMillis ~/ 1000);

      _noteStorage.updateNote(edited);
      final addedCards = <Card>[];
      final requiredOrdinals = _requiredCardOrdinals(
        edited,
        notetype,
        existingCards,
      );
      if (requiredOrdinals.isNotEmpty) {
        final targetDeck = _deckForGeneratedCard(
          existingCards,
          notetype.id.value,
        );
        final existingDue = _existingNewCardDue(existingCards);
        final duePosition = existingDue == null
            ? _nextGeneratedCardPosition()
            : null;
        for (final ordinal in requiredOrdinals) {
          final templateIndex = notetype.isCloze ? 0 : ordinal;
          final templateTarget = notetype.isCloze
              ? Int64.ZERO
              : notetype.templates[templateIndex].config.targetDeckId;
          final deckId = _deckForAdding(
            templateTarget == Int64.ZERO ? targetDeck : templateTarget,
          );
          final due = existingDue ?? _dueForDeck(duePosition!, deckId);
          final card = Card.newCard(
            noteId: edited.id,
            templateIdx: ordinal,
            deckId: deckId,
            due: due,
          );
          final id = _addCardSync(card);
          addedCards.add(_cardWithId(card, id));
        }
      }
      _database.execute('UPDATE col SET mod = ?', [modifiedAtMillis]);
      _database.execute('RELEASE core_update_existing_note');
      result = ExistingNoteUpdateResult(
        changed: true,
        note: edited,
        addedCards: List.unmodifiable(addedCards),
        undoRecord: UpdatedNoteUndoRecord(
          original,
          collectionMtimeMillis: collectionMtimeMillis,
          nextCardPositionConfigBefore: nextPositionConfigBefore,
          nextCardPositionConfigAfter: _readExistingNoteUpdateConfigSnapshot(
            'nextPos',
          ),
          addedTags: addedTags,
        ),
      );
    } catch (error, stackTrace) {
      try {
        _database.execute('ROLLBACK TO core_update_existing_note');
        _database.execute('RELEASE core_update_existing_note');
      } catch (_) {
        // Keep the operation's original failure observable.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return result;
  }

  bool get _normalizeNoteText {
    final value =
        readCollectionConfig('normalize_note_text') ??
        readCollectionConfig('normalizeNoteText');
    return value is bool ? value : true;
  }

  List<String> _canonifyEditedTags(Note note) {
    final canonicalByFoldedName = <String, String>{};
    final addedTags = <String>[];
    for (final raw in note.tags) {
      for (final tag in raw.split(RegExp(r'[ \u3000]+'))) {
        if (tag.isEmpty) continue;
        final normalized = tag
            .split('::')
            .map((component) {
              final cleaned = unorm
                  .nfc(component)
                  .replaceAll(RegExp(r'[\x00-\x1f\x7f \u3000]'), '')
                  .trim();
              return cleaned.isEmpty ? 'blank' : cleaned;
            })
            .join('::');
        var preferred = _tagStorage.preferredTagCase(normalized);
        if (preferred == null) {
          final components = normalized.split('::');
          for (
            var parentCount = components.length - 1;
            parentCount > 0 && preferred == null;
            parentCount--
          ) {
            final parent = components.take(parentCount).join('::');
            final storedParent = _tagStorage.preferredTagCase(parent);
            if (storedParent != null) {
              preferred =
                  '$storedParent::${components.skip(parentCount).join('::')}';
            }
          }
        }
        final finalName = preferred ?? normalized;
        final folded = unicodeCaseFold(finalName);
        canonicalByFoldedName.putIfAbsent(folded, () => finalName);
        if (_tagStorage.preferredTagCase(finalName) == null) {
          _database.execute(
            'INSERT OR IGNORE INTO tags (tag, usn, collapsed) VALUES (?, -1, 1)',
            [finalName],
          );
          addedTags.add(finalName);
        }
      }
    }
    final canonical = canonicalByFoldedName.keys.toList()..sort();
    note.tags
      ..clear()
      ..addAll(canonical.map((folded) => canonicalByFoldedName[folded]!));
    return addedTags;
  }

  List<int> _requiredCardOrdinals(
    Note note,
    Notetype notetype,
    List<Card> existing,
  ) {
    final existingOrds = existing.map((card) => card.templateIdx).toSet();
    final ordinals = <int>[];
    if (notetype.isCloze) {
      final clozes = clozeNumbersInFields(
        note.fields,
      ).map((number) => (number - 1).clamp(0, 499)).toSet();
      ordinals.addAll(
        clozes.where((ordinal) => !existingOrds.contains(ordinal)),
      );
    } else {
      for (var ordinal = 0; ordinal < notetype.templates.length; ordinal++) {
        if (existingOrds.contains(ordinal)) {
          continue;
        }
        if (_normalTemplateRendersForNote(note, notetype, ordinal)) {
          ordinals.add(ordinal);
        }
      }
    }
    if (existing.isEmpty && ordinals.isEmpty) return [0];
    ordinals.sort();
    return ordinals;
  }

  bool _normalTemplateRendersForNote(
    Note note,
    Notetype notetype,
    int ordinal,
  ) {
    if (ordinal < 0 || ordinal >= notetype.templates.length) return false;
    final nonempty = note.nonEmptyFields(notetype.fields);
    if (note.tags.isNotEmpty) nonempty.add('Tags');
    return templateRendersWithFields(
      notetype.templates[ordinal].config.qFormat,
      nonempty,
    );
  }

  Int64 _deckForGeneratedCard(List<Card> existing, Int64 notetypeId) {
    final deckIds = existing
        .map(
          (card) => card.originalDeckId == Int64.ZERO
              ? card.deckId
              : card.originalDeckId,
        )
        .toSet();
    if (deckIds.length == 1 && deckIds.single != Int64.ZERO) {
      final existingDeck = _deckStorage.getDeck(deckIds.single);
      if (existingDeck?.configId != null) return deckIds.single;
    }
    final lastDeck = _readConfigInt64('_nt_${notetypeId}_lastDeck');
    if (lastDeck != null) {
      final deck = _deckStorage.getDeck(lastDeck);
      if (deck?.configId != null) return lastDeck;
    }
    return Int64.ONE;
  }

  int? _existingNewCardDue(List<Card> existing) {
    final priorNew = existing.where((card) => card.ctype == CardType.newCard);
    if (priorNew.isNotEmpty) {
      final card = priorNew.first;
      final position = card.originalDue != 0 ? card.originalDue : card.due;
      return position < 0 ? 0 : position;
    }
    return null;
  }

  int _nextGeneratedCardPosition({int? modifiedAtMillis}) {
    final next = readCollectionConfig('nextPos');
    final position = next is int ? next : 0;
    _setOperationConfig(
      'nextPos',
      jsonEncode((position + 1) & 0xffffffff),
      modifiedAtMillis ?? DateTime.now().millisecondsSinceEpoch,
    );
    return position;
  }

  bool _setOperationConfig(String key, String encodedJson, int nowMillis) {
    final rows = _database.select('SELECT val FROM config WHERE key = ?', [
      key,
    ]);
    if (rows.isNotEmpty &&
        utf8.decode(rows.single['val'] as List<int>) == encodedJson) {
      return false;
    }
    _database.execute(
      'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) VALUES (?, -1, ?, ?)',
      [key, nowMillis ~/ 1000, utf8.encode(encodedJson)],
    );
    return true;
  }

  int _dueForDeck(int position, Int64 deckId) {
    final deck = _deckStorage.getDeck(deckId);
    if (deck == null || deck.configId == null) {
      throw StateError('deck does not exist or is filtered: $deckId');
    }
    final config = _deckConfigStorage.getDeckConfig(deck.configId!);
    if (config == null) {
      throw StateError('missing deck configuration: ${deck.configId}');
    }
    final random =
        config.inner.newCardInsertOrder ==
        protoConfig
            .DeckConfig_Config_NewCardInsertOrder
            .NEW_CARD_INSERT_ORDER_RANDOM;
    return random ? coreRandomPosition(position) : position;
  }

  Int64 _deckForAdding(Int64 targetDeckId) {
    final deck = _deckStorage.getDeck(targetDeckId);
    if (deck?.configId != null) return targetDeckId;
    final defaultDeck = _deckStorage.getDeck(Int64.ONE);
    if (defaultDeck?.configId == null) {
      throw StateError('invalid default deck');
    }
    return Int64.ONE;
  }

  Card _cardWithId(Card card, Int64 id) => Card(
    id: id,
    noteId: card.noteId,
    deckId: card.deckId,
    templateIdx: card.templateIdx,
    mtimeSecs: card.mtimeSecs,
    usn: card.usn,
    ctype: card.ctype,
    queue: card.queue,
    due: card.due,
    interval: card.interval,
    easeFactorRaw: card.easeFactorRaw,
    reps: card.reps,
    lapses: card.lapses,
    remainingStepsRaw: card.remainingStepsRaw,
    originalDue: card.originalDue,
    originalDeckId: card.originalDeckId,
    flags: card.flags,
    originalPosition: card.originalPosition,
    memoryState: card.memoryState,
    desiredRetention: card.desiredRetention,
    decay: card.decay,
    lastReviewTimeSecs: card.lastReviewTimeSecs,
    customData: card.customData,
  );

  /// Inserts a new note, assigning its generated SQLite row ID to [note].
  Future<void> addNote(Note note) async {
    await _withExternalCollectionMutation(() => _noteStorage.addNote(note));
    await _flushIfAutocommit();
  }

  /// Retries persistence of writes already committed to SQLite.
  ///
  /// This is useful after an operation reports a driver flush failure after
  /// its SQLite transaction has committed. It does not run a transaction or
  /// change collection data. A retry is only valid while storage is open and
  /// no SQLite transaction is active.
  Future<void> flushPendingWrites() async {
    if (_closing || _connectionClosed || _closed) {
      throw StateError('collection storage is closing');
    }
    if (!_database.autocommit) throw StateError('active transaction');
    await _flush();
  }

  /// Returns a portable SQLite backup of committed collection state.
  ///
  /// The driver uses SQLite's backup operation, so the live connection stays
  /// open and subsequent writes do not alter the returned bytes. An active
  /// transaction is rejected because its commit state is ambiguous.
  Future<Uint8List> createSnapshot() async {
    if (_closing || _connectionClosed || _closed) {
      throw StateError('collection storage is closing');
    }
    final snapshot = _driver.snapshot;
    if (snapshot == null) {
      throw const PortableIoUnsupported('database snapshot');
    }
    final operationDone = await _acquireCollectionUndoOperation();
    final snapshotDone = Completer<void>();
    _portableSnapshotDone = snapshotDone;
    _portableSnapshotStarting = true;
    try {
      if (_closing || _connectionClosed || _closed) {
        throw StateError('collection storage is closing');
      }
      if (!_database.autocommit) throw StateError('active transaction');
      await _flush();
      if (!_database.autocommit) throw StateError('active transaction');
      return await snapshot(_database);
    } finally {
      _portableSnapshotStarting = false;
      if (identical(_portableSnapshotDone, snapshotDone)) {
        _portableSnapshotDone = null;
      }
      snapshotDone.complete();
      _releaseCollectionUndoOperation(operationDone);
    }
  }

  /// Runs [build] against a detached database copy while blocking collection
  /// mutations and returning only the complete result.
  Future<Uint8List> exportFromSnapshot(
    Future<Uint8List> Function(CommonDatabase copy) build,
  ) async {
    if (_closing || _connectionClosed || _closed) {
      throw StateError('collection storage is closing');
    }
    final exportSnapshot = _driver.exportFromSnapshot;
    if (exportSnapshot == null) {
      throw const PortableIoUnsupported('detached database export');
    }
    final operationDone = await _acquireCollectionUndoOperation();
    final snapshotDone = Completer<void>();
    _portableSnapshotDone = snapshotDone;
    _portableSnapshotStarting = true;
    try {
      if (_closing || _connectionClosed || _closed) {
        throw StateError('collection storage is closing');
      }
      if (!_database.autocommit) throw StateError('active transaction');
      await _flush();
      if (!_database.autocommit) throw StateError('active transaction');
      return await exportSnapshot(_database, (copy) async {
        await _configureApkgClone(copy, _options);
        return build(copy);
      });
    } finally {
      _portableSnapshotStarting = false;
      if (identical(_portableSnapshotDone, snapshotDone)) {
        _portableSnapshotDone = null;
      }
      snapshotDone.complete();
      _releaseCollectionUndoOperation(operationDone);
    }
  }

  /// Reads a named media object. Names are validated before reaching the host.
  Future<Stream<List<int>>?> readMedia(String filename) {
    final safeName = validateAnkiMediaFilename(filename);
    final media = _driver.mediaStorage;
    if (media == null) {
      throw const PortableIoUnsupported('collection media read');
    }
    return media.read(safeName);
  }

  /// Lists media filenames available to this collection.
  Future<Iterable<String>> listMedia() async {
    final media = _driver.mediaStorage;
    if (media == null) {
      throw const PortableIoUnsupported('collection media listing');
    }
    return (await media.list()).map(validateAnkiMediaFilename).toList();
  }

  /// Adds a new note to [deckId], generating the cards Core requires.
  ///
  /// The caller selects the deck (including resolving any host-side default
  /// deck preference). The note, registered tags, cards, config updates, and
  /// collection modification time are committed together. Note, SQL, card,
  /// and config failures before savepoint release roll back and leave [note]
  /// with its original ID. The driver's async flush occurs after SQLite
  /// commits; if that flush fails, this future reports a post-commit error and
  /// the caller must re-read the collection before retrying.
  Future<AddNoteResult> addNoteToDeck(Note note, Int64 deckId) async {
    final operationResult = await _withExternalCollectionMutation(() async {
      if (_closing || _connectionClosed || _closed) {
        throw StateError('collection storage is closing');
      }
      if (note.id != Int64.ZERO) {
        throw StateError('note ID must be zero before it can be added');
      }
      final notetypes = await getNotetypesByIds([NotetypeId(note.notetypeId)]);
      if (notetypes.isEmpty) {
        throw StateError('missing note type: ${note.notetypeId}');
      }
      // Another call may have saved this same mutable Note while the lookup was
      // pending.
      if (note.id != Int64.ZERO) {
        throw StateError('note ID must be zero before it can be added');
      }
      final notetype = notetypes.single;
      final operationMillis =
          _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
      final originalId = note.id;
      _database.execute('SAVEPOINT core_add_note');
      late final AddNoteResult result;
      try {
        final addedTags = _canonifyEditedTags(note);
        note.prepareForUpdate(notetype, normalizeText: _normalizeNoteText);
        note.markModified(-1, mtimeSecs: operationMillis ~/ 1000);
        _noteStorage.addNote(note);

        final lastDeckConfigKey = '_nt_${note.notetypeId}_lastDeck';
        final lastNotetypeConfigKey = '_deck_${deckId}_lastNotetype';
        var configChanged = false;
        var nextPositionChanged = false;
        var generatedCardCount = 0;
        final ordinals = _requiredCardOrdinals(note, notetype, const []);
        if (ordinals.isNotEmpty) {
          final nextPosition = _nextGeneratedCardPosition(
            modifiedAtMillis: operationMillis,
          );
          nextPositionChanged = true;
          for (final ordinal in ordinals) {
            final hasTemplateTarget =
                !notetype.isCloze &&
                _normalTemplateRendersForNote(note, notetype, ordinal);
            final templateTargetDeck = hasTemplateTarget
                ? notetype.templates[ordinal].config.targetDeckId
                : Int64.ZERO;
            final targetDeck = templateTargetDeck == Int64.ZERO
                ? deckId
                : templateTargetDeck;
            final actualDeck = _deckForAdding(targetDeck);
            final due = _dueForDeck(nextPosition, actualDeck);
            final card = Card.newCard(
              noteId: note.id,
              templateIdx: ordinal,
              deckId: actualDeck,
              due: due,
            );
            _addCardSync(card);
            generatedCardCount++;
          }
        }

        final configMillis = operationMillis;
        configChanged |= _setOperationConfig(
          lastDeckConfigKey,
          _jsonInt64(deckId),
          configMillis,
        );
        configChanged |= _setOperationConfig(
          lastNotetypeConfigKey,
          _jsonInt64(note.notetypeId),
          configMillis,
        );
        configChanged |= _setOperationConfig(
          'curModel',
          _jsonInt64(note.notetypeId),
          configMillis,
        );
        _database.execute('UPDATE col SET mod = ?', [operationMillis]);
        _database.execute('RELEASE core_add_note');
        result = AddNoteResult(
          note: note,
          generatedCardCount: generatedCardCount,
          changes: protoCollection.OpChanges(
            note: true,
            card: generatedCardCount > 0,
            tag: addedTags.isNotEmpty,
            config: configChanged || nextPositionChanged,
            mtime: true,
          ),
        );
      } catch (error, stackTrace) {
        try {
          _database.execute('ROLLBACK TO core_add_note');
          _database.execute('RELEASE core_add_note');
        } catch (_) {
          // Preserve the original failure.
        }
        note.id = originalId;
        Error.throwWithStackTrace(error, stackTrace);
      }
      return result;
    });
    await _flushIfAutocommit();
    return operationResult;
  }

  /// Inserts [note] only when its ID is unused.
  Future<bool> addNoteIfUnique(Note note) async {
    final inserted = await _withExternalCollectionMutation(
      () => _noteStorage.addNoteIfUnique(note),
    );
    await _flushIfAutocommit();
    return inserted;
  }

  /// Inserts or replaces the row with [note]'s ID.
  Future<void> addOrUpdateNote(Note note) async {
    await _withExternalCollectionMutation(
      () => _noteStorage.addOrUpdateNote(note),
    );
    await _flushIfAutocommit();
  }

  /// Removes a note; a missing ID is a successful no-op.
  Future<void> removeNote(Int64 noteId) async {
    await _withExternalCollectionMutation(
      () => _noteStorage.removeNote(noteId),
    );
    await _flushIfAutocommit();
  }

  /// Returns source-compatible review log row operations on this collection.
  RevlogStorage get revlog => _revlogStorage;

  bool get canUndoCollectionOperation => _collectionUndoSteps.isNotEmpty;
  bool get canRedoCollectionOperation => _collectionRedoSteps.isNotEmpty;
  String? get collectionUndoLabel =>
      _collectionUndoSteps.isEmpty ? null : _collectionUndoSteps.last.label;
  String? get collectionRedoLabel =>
      _collectionRedoSteps.isEmpty ? null : _collectionRedoSteps.last.label;
  bool get collectionUndoIsCustom =>
      _collectionUndoSteps.isNotEmpty && _collectionUndoSteps.last.isCustom;
  bool get collectionRedoIsCustom =>
      _collectionRedoSteps.isNotEmpty && _collectionRedoSteps.last.isCustom;
  List<CollectionUndoChange> get collectionUndoChanges =>
      _collectionUndoSteps.isEmpty
      ? const []
      : List.unmodifiable(_collectionUndoSteps.last.changes);
  List<CollectionUndoChange> get collectionRedoChanges =>
      _collectionRedoSteps.isEmpty
      ? const []
      : List.unmodifiable(
          _inverseCollectionUndoChanges(_collectionRedoSteps.last.changes),
        );
  int get collectionUndoLastStep => _collectionUndoStepCounter;
  int get collectionUndoGeneration => _collectionUndoGeneration;
  bool get collectionUndoHasEntryAtCurrentGeneration =>
      _collectionUndoLastEntryGeneration == _collectionUndoGeneration;

  /// Adds a named empty step that later operations can be merged into.
  int addCustomUndoEntry(String name) {
    if (name.isEmpty)
      throw ArgumentError.value(name, 'name', 'must not be empty');
    _collectionUndoStepCounter++;
    _collectionRedoSteps.clear();
    _collectionUndoSteps.add(
      _CollectionUndoStep(
        label: name,
        counter: _collectionUndoStepCounter,
        actions: [],
        isCustom: true,
      ),
    );
    if (_collectionUndoSteps.length > 30) _collectionUndoSteps.removeAt(0);
    _collectionUndoGeneration++;
    _collectionUndoLastEntryGeneration = _collectionUndoGeneration;
    return _collectionUndoStepCounter;
  }

  /// Merges newer undo entries into [target], matching Core's custom-step
  /// restore-point behavior. The target keeps its operation label and counter.
  void mergeUndoEntries(int target) {
    final targetIndex = _collectionUndoSteps.indexWhere(
      (step) => step.counter == target,
    );
    if (targetIndex < 0) {
      throw ArgumentError.value(target, 'target', 'undo step was not found');
    }
    final merged = _collectionUndoSteps.sublist(targetIndex + 1);
    final targetStep = _collectionUndoSteps[targetIndex];
    for (final step in merged) {
      targetStep.actions.addAll(step.actions);
    }
    if (merged.isNotEmpty) {
      _collectionUndoSteps.removeRange(
        targetIndex + 1,
        _collectionUndoSteps.length,
      );
    }
    _collectionUndoStepCounter = target;
    _collectionUndoGeneration++;
    _collectionUndoLastEntryGeneration = _collectionUndoGeneration;
  }

  /// Commits one collection operation and retains its exact inverse in the
  /// same bounded, process-local history used by Card Browser bulk actions.
  Future<bool> runUndoableCollectionOperation({
    String label = 'Collection operation',
    CollectionUndoOperation? operation,
    bool captureSqlChanges = true,
    List<CollectionUndoChange> additionalChanges = const [],
    List<CollectionUndoChange> Function()? collectAdditionalChanges,
    Future<bool> Function()? prepare,
    required Future<void> Function() apply,
    Future<void> Function()? undo,
    Future<void> Function()? redo,
    void Function(int generation)? onCommitted,
  }) async {
    final operationDone = await _acquireCollectionUndoOperation();
    _collectionUndoStepCounter++;
    try {
      await beginExclusive();
      final externalMutationGeneration =
          _collectionUndoExternalMutationGeneration;
      final session = captureSqlChanges ? _createCollectionUndoSession() : null;
      Changeset? changeset;
      late final bool prepared;
      try {
        prepared = await runZoned(() async {
          if (prepare != null && !await prepare()) {
            _executeCached('rollback');
            return false;
          }
          await apply();
          changeset = session?.changeset();
          _executeCached('commit');
          return true;
        }, zoneValues: {_collectionUndoOperationZoneKey: this});
      } catch (error, stackTrace) {
        try {
          _executeCached('rollback');
        } catch (_) {
          // Keep the operation failure visible.
        }
        Error.throwWithStackTrace(error, stackTrace);
      } finally {
        session?.delete();
      }
      if (!prepared) {
        if (_collectionRedoSteps.isNotEmpty) {
          _collectionRedoSteps.clear();
          _collectionUndoGeneration++;
        }
        return false;
      }
      final hasChangeset = changeset?.isNotEmpty == true;
      final capturedChanges = hasChangeset
          ? _collectionUndoChangesFromChangeset(changeset!)
          : const <CollectionUndoChange>[];
      final extraChanges = [
        ...additionalChanges,
        ...?collectAdditionalChanges?.call(),
      ];
      final hasCallbacks = undo != null && redo != null;
      if (captureSqlChanges &&
          !hasChangeset &&
          extraChanges.isEmpty &&
          !hasCallbacks) {
        if (_collectionRedoSteps.isNotEmpty) {
          _collectionRedoSteps.clear();
          _collectionUndoGeneration++;
        }
        return true;
      }
      if (!hasChangeset && !hasCallbacks && extraChanges.isEmpty) return true;
      if (externalMutationGeneration ==
          _collectionUndoExternalMutationGeneration) {
        _collectionRedoSteps.clear();
        _collectionUndoSteps.add(
          _CollectionUndoStep(
            label: operation == CollectionUndoOperation.custom
                ? label
                : operation?.name ?? _operationKeyFromLegacyLabel(label),
            counter: _collectionUndoStepCounter,
            isCustom: operation == CollectionUndoOperation.custom,
            actions: [
              _CollectionUndoAction(
                undo: undo,
                redo: redo,
                undoChangeset: hasChangeset ? -changeset! : null,
                redoChangeset: hasChangeset ? changeset : null,
                changes: List.unmodifiable([
                  ...capturedChanges,
                  ...extraChanges,
                ]),
              ),
            ],
          ),
        );
        if (_collectionUndoSteps.length > 30) _collectionUndoSteps.removeAt(0);
      }
      _collectionUndoGeneration++;
      _collectionUndoLastEntryGeneration = _collectionUndoGeneration;
      onCommitted?.call(_collectionUndoGeneration);
      await _flush();
      return true;
    } finally {
      if (identical(_collectionUndoOperationDone, operationDone)) {
        _collectionUndoOperationDone = null;
      }
      operationDone.complete();
    }
  }

  /// Starts a Core-compatible SQLite session over collection tables with a
  /// declared primary key. The session captures row-level inverses for notes,
  /// cards, decks, tags, revlogs, collection configuration, and custom rows
  /// changed by the operation, including trigger effects.
  Session _createCollectionUndoSession() {
    final session = Session(_database);
    try {
      final tables = _database.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      for (final row in tables) {
        final name = row['name'] as String;
        final quotedName = '"${name.replaceAll('"', '""')}"';
        final columns = _database.select('PRAGMA table_info($quotedName)');
        if (columns.any((column) => (column['pk'] as int) > 0)) {
          session.attach(name);
        }
      }
      return session;
    } on Object {
      session.delete();
      rethrow;
    }
  }

  List<CollectionUndoChange> _collectionUndoChangesFromChangeset(
    Changeset changeset,
  ) {
    final changes = <CollectionUndoChange>[];
    for (final change in changeset) {
      final table = change.table;
      final kind = switch (table) {
        'cards' => CollectionUndoChangeKind.card,
        'notes' => CollectionUndoChangeKind.note,
        'decks' => CollectionUndoChangeKind.deck,
        'deck_config' => CollectionUndoChangeKind.deckConfig,
        'tags' => CollectionUndoChangeKind.tag,
        'revlog' => CollectionUndoChangeKind.revlog,
        'config' => CollectionUndoChangeKind.config,
        'col' => CollectionUndoChangeKind.collection,
        'notetypes' ||
        'fields' ||
        'templates' => CollectionUndoChangeKind.notetype,
        _ => CollectionUndoChangeKind.custom,
      };
      final variant = switch (change.operation) {
        SqliteUpdateKind.insert => CollectionUndoChangeVariant.added,
        SqliteUpdateKind.update =>
          table == 'col'
              ? CollectionUndoChangeVariant.modified
              : CollectionUndoChangeVariant.updated,
        SqliteUpdateKind.delete => CollectionUndoChangeVariant.removed,
      };
      final before = change.oldValues == null
          ? null
          : List<Object?>.unmodifiable(change.oldValues!);
      final after = change.newValues == null
          ? null
          : List<Object?>.unmodifiable(change.newValues!);
      changes.add(
        CollectionUndoChange(
          kind: kind,
          variant: variant,
          table: table,
          columns: _collectionColumnsForTable(table),
          operation: change.operation,
          before: before,
          after: after,
        ),
      );
      if (table == 'notes' &&
          _changesetColumnChanged(
            table,
            'tags',
            change.oldValues,
            change.newValues,
          )) {
        changes.add(
          CollectionUndoChange(
            kind: CollectionUndoChangeKind.noteTags,
            variant: CollectionUndoChangeVariant.tagsUpdated,
            table: table,
            columns: _collectionColumnsForTable(table),
            operation: change.operation,
            before: before,
            after: after,
          ),
        );
      }
      if (table == 'col' &&
          _changesetColumnChanged(
            table,
            'scm',
            change.oldValues,
            change.newValues,
          )) {
        changes.add(
          CollectionUndoChange(
            kind: CollectionUndoChangeKind.collection,
            variant: CollectionUndoChangeVariant.schemaModified,
            table: table,
            columns: _collectionColumnsForTable(table),
            operation: change.operation,
            before: before,
            after: after,
          ),
        );
      }
    }
    return List.unmodifiable(changes);
  }

  List<String> _collectionColumnsForTable(String table) {
    final quotedTable = '"${table.replaceAll('"', '""')}"';
    return List.unmodifiable(
      _database
          .select('PRAGMA table_info($quotedTable)')
          .map((row) => row['name'] as String),
    );
  }

  bool _changesetColumnChanged(
    String table,
    String column,
    List<Object?>? before,
    List<Object?>? after,
  ) {
    if (before == null || after == null) return false;
    final quotedTable = '"${table.replaceAll('"', '""')}"';
    final columns = _database.select('PRAGMA table_info($quotedTable)');
    final index = columns.indexWhere((row) => row['name'] == column);
    return index >= 0 &&
        index < before.length &&
        index < after.length &&
        before[index] != after[index];
  }

  List<CollectionUndoChange> _mergeCollectionUndoChanges(
    List<CollectionUndoChange> earlier,
    List<CollectionUndoChange> later,
  ) {
    final merged = [...earlier];
    for (final change in later) {
      final key = _collectionUndoChangeKey(change);
      final index = key == null
          ? -1
          : merged.indexWhere(
              (existing) => _collectionUndoChangeKey(existing) == key,
            );
      if (index < 0) {
        merged.add(change);
        continue;
      }
      final previous = merged[index];
      final before = previous.before;
      final after = change.after;
      if (before == null && after == null) {
        merged.removeAt(index);
        continue;
      }
      final variant = previous.kind == CollectionUndoChangeKind.noteTags
          ? CollectionUndoChangeVariant.tagsUpdated
          : before == null
          ? CollectionUndoChangeVariant.added
          : after == null
          ? CollectionUndoChangeVariant.removed
          : CollectionUndoChangeVariant.updated;
      final operation = switch (variant) {
        CollectionUndoChangeVariant.added => SqliteUpdateKind.insert,
        CollectionUndoChangeVariant.removed => SqliteUpdateKind.delete,
        _ => SqliteUpdateKind.update,
      };
      merged[index] = CollectionUndoChange(
        kind: previous.kind,
        variant: variant,
        table: previous.table,
        columns: previous.columns,
        operation: operation,
        before: before,
        after: after,
      );
    }
    return List.unmodifiable(merged);
  }

  List<CollectionUndoChange> _inverseCollectionUndoChanges(
    Iterable<CollectionUndoChange> changes,
  ) => [
    for (final change in changes.toList().reversed)
      CollectionUndoChange(
        kind: change.kind,
        variant: switch (change.variant) {
          CollectionUndoChangeVariant.added =>
            CollectionUndoChangeVariant.removed,
          CollectionUndoChangeVariant.removed =>
            CollectionUndoChangeVariant.added,
          CollectionUndoChangeVariant.graveAdded =>
            CollectionUndoChangeVariant.graveRemoved,
          CollectionUndoChangeVariant.graveRemoved =>
            CollectionUndoChangeVariant.graveAdded,
          CollectionUndoChangeVariant.cardAnswered =>
            CollectionUndoChangeVariant.cardAnswerUndone,
          CollectionUndoChangeVariant.cardAnswerUndone =>
            CollectionUndoChangeVariant.cardAnswered,
          CollectionUndoChangeVariant.updated ||
          CollectionUndoChangeVariant.tagsUpdated ||
          CollectionUndoChangeVariant.modified ||
          CollectionUndoChangeVariant.schemaModified ||
          CollectionUndoChangeVariant.custom => change.variant,
        },
        table: change.table,
        columns: change.columns,
        operation: switch (change.operation) {
          SqliteUpdateKind.insert => SqliteUpdateKind.delete,
          SqliteUpdateKind.delete => SqliteUpdateKind.insert,
          SqliteUpdateKind.update => SqliteUpdateKind.update,
        },
        before: change.after,
        after: change.before,
      ),
  ];

  String? _collectionUndoChangeKey(CollectionUndoChange change) {
    final values = change.before ?? change.after;
    if (values == null) return null;
    final table = '"${change.table.replaceAll('"', '""')}"';
    final schema = _database.select('PRAGMA table_info($table)');
    final keys = <(String, int)>[
      for (var index = 0; index < schema.length; index++)
        if ((schema[index]['pk'] as int) > 0)
          (schema[index]['name'] as String, index),
    ];
    if (keys.isEmpty) return null;
    return [
      change.kind.name,
      change.table,
      for (final (name, index) in keys) '$name=${values[index]}',
    ].join('|');
  }

  String _operationKeyFromLegacyLabel(String label) => switch (label) {
    'Edit Note' => CollectionUndoOperation.updateNote.name,
    'Delete Cards' => CollectionUndoOperation.deleteCards.name,
    'Suspend Cards' => CollectionUndoOperation.suspendCards.name,
    'Bury Cards' => CollectionUndoOperation.buryCards.name,
    'Unbury Cards' => CollectionUndoOperation.unburyCards.name,
    'Delete Deck' => CollectionUndoOperation.deleteDeck.name,
    'Empty Filtered Deck' => CollectionUndoOperation.emptyFilteredDeck.name,
    'Build Filtered Deck' => CollectionUndoOperation.buildFilteredDeck.name,
    "Extend Today's Study Limits" =>
      CollectionUndoOperation.extendStudyLimits.name,
    'Change Deck Description' =>
      CollectionUndoOperation.changeDeckDescription.name,
    'Change Deck Daily Limits' =>
      CollectionUndoOperation.changeDeckDailyLimits.name,
    'Create Deck' => CollectionUndoOperation.createDeck.name,
    _ => label,
  };

  Future<Completer<void>> _acquireCollectionUndoOperation() {
    if (identical(Zone.current[_collectionUndoOperationZoneKey], this)) {
      return Future.error(StateError('nested undoable collection operation'));
    }
    final activeOperation = _collectionUndoOperationDone;
    if (activeOperation == null) {
      final operationDone = Completer<void>();
      _collectionUndoOperationDone = operationDone;
      return Future.value(operationDone);
    }
    return activeOperation.future.then(
      (_) => _acquireCollectionUndoOperation(),
    );
  }

  void _releaseCollectionUndoOperation(Completer<void> operationDone) {
    if (identical(_collectionUndoOperationDone, operationDone)) {
      _collectionUndoOperationDone = null;
    }
    operationDone.complete();
  }

  void _throwIfExternalCollectionUndoOperationIsActive() {
    if (_collectionUndoOperationDone != null &&
        !identical(Zone.current[_collectionUndoOperationZoneKey], this) &&
        !identical(Zone.current[_externalCollectionMutationZoneKey], this)) {
      throw StateError('collection mutation during undoable operation');
    }
  }

  Future<void> undoLastCollectionOperation() async {
    final operationDone = await _acquireCollectionUndoOperation();
    try {
      if (_collectionUndoSteps.isEmpty) {
        throw StateError('no collection operation to undo');
      }
      final externalMutationGeneration =
          _collectionUndoExternalMutationGeneration;
      final step = _collectionUndoSteps.removeLast();
      _collectionUndoStepCounter++;
      if (step.noteUpdate != null) _noteUpdateUndoCounter++;
      try {
        await _replayCollectionOperation(() async {
          for (final action in step.actions.reversed) {
            await _applyCollectionUndoAction(action, undo: true);
          }
        });
      } catch (_) {
        if (externalMutationGeneration ==
            _collectionUndoExternalMutationGeneration) {
          _collectionUndoSteps.add(step);
        }
        rethrow;
      }
      if (externalMutationGeneration ==
          _collectionUndoExternalMutationGeneration) {
        step.counter = _collectionUndoStepCounter;
        _collectionRedoSteps.add(step);
      }
      _collectionUndoGeneration++;
      await _flushAfterCommittedUndoRedo();
    } finally {
      _releaseCollectionUndoOperation(operationDone);
    }
  }

  Future<void> _replayCollectionOperation(
    Future<void> Function() action,
  ) async {
    await beginExclusive();
    try {
      await runZoned(() async {
        await action();
        _executeCached('commit');
      }, zoneValues: {_collectionUndoOperationZoneKey: this});
    } catch (error, stackTrace) {
      try {
        _executeCached('rollback');
      } catch (_) {}
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Reapplies the most recently undone browser collection operation.
  Future<void> redoLastCollectionOperation() async {
    final operationDone = await _acquireCollectionUndoOperation();
    try {
      if (_collectionRedoSteps.isEmpty) {
        throw StateError('no collection operation to redo');
      }
      final externalMutationGeneration =
          _collectionUndoExternalMutationGeneration;
      final step = _collectionRedoSteps.removeLast();
      _collectionUndoStepCounter++;
      if (step.noteUpdate != null) _noteUpdateUndoCounter++;
      try {
        await _replayCollectionOperation(() async {
          for (final action in step.actions) {
            await _applyCollectionUndoAction(action, undo: false);
          }
        });
      } catch (_) {
        if (externalMutationGeneration ==
            _collectionUndoExternalMutationGeneration) {
          _collectionRedoSteps.add(step);
        }
        rethrow;
      }
      if (externalMutationGeneration ==
          _collectionUndoExternalMutationGeneration) {
        step.counter = _collectionUndoStepCounter;
        _collectionUndoSteps.add(step);
      }
      _collectionUndoGeneration++;
      await _flushAfterCommittedUndoRedo();
    } finally {
      _releaseCollectionUndoOperation(operationDone);
    }
  }

  Future<void> _applyCollectionUndoAction(
    _CollectionUndoAction action, {
    required bool undo,
  }) async {
    // Explicit actions may include state outside captured SQLite tables
    // (such as the current deck selection). They define the complete logical
    // replay when supplied; changesets are the automatic fallback.
    final callback = undo ? action.undo : action.redo;
    if (callback != null) {
      await callback();
      return;
    }
    final changeset = undo ? action.undoChangeset : action.redoChangeset;
    if (changeset != null) {
      changeset.applyTo(_database);
      return;
    }
    throw StateError(
      undo
          ? 'collection undo entry has no inverse'
          : 'collection redo entry has no forward action',
    );
  }

  Future<void> _flushAfterCommittedUndoRedo() async {
    try {
      await _flush();
    } on Object {
      // SQLite has already committed and history has advanced. Retry once,
      // then leave the committed undo/redo outcome reachable to its caller.
      try {
        await flushPendingWrites();
      } on Object {
        // As with deck removal, a persistent driver failure must not make a
        // committed collection operation look like it was rolled back.
      }
    }
  }

  /// Removes a deck and its descendants using Anki Core's deck removal rules.
  ///
  /// Cards in normal decks and notes left without cards are deleted. Cards in
  /// filtered decks are returned to their original deck and scheduling state.
  /// The operation is atomic and participates in the collection undo history.
  Future<DeckRemovalResult> removeDeckAndChildren(
    Int64 deckId, {
    String defaultDeckName = 'Default',
  }) async {
    late Deck target;
    late List<Deck> decks;
    late int now;
    late Int64 afterMtime;
    late Int64 beforeMtime;
    late bool currentDeckWasDeleted;
    final cardsToDelete = <Card>[];
    final cardsToReturn = <Card>[];
    final revlogs = <RevlogEntry>[];
    final notes = <Note>[];
    final cardGraves = <Int64, bool>{};
    final noteGraves = <Int64, bool>{};
    final auxConfigRows = <Map<String, Object?>>[];
    final decksToRemove = <Deck>[];
    final deckGraves = <Int64, bool>{};
    late List<Map<String, Object?>> currentDeckConfig;

    var committed = false;
    var prepared = false;
    var persistenceWarning = false;
    var committedUndoGeneration = 0;
    try {
      committed = await runUndoableCollectionOperation(
        operation: CollectionUndoOperation.deleteDeck,
        captureSqlChanges: true,
        prepare: () async {
          final currentTarget = _deckStorage.getDeck(deckId);
          if (currentTarget == null) {
            throw StateError('deck not found: $deckId');
          }
          target = currentTarget;
          decks = _deckStorage.deckWithChildren(deckId);
          now = DateTime.now().toUtc().millisecondsSinceEpoch;
          afterMtime = Int64(now);
          beforeMtime = collectionModifiedAt;
          currentDeckWasDeleted = decks.any((deck) => deck.id == currentDeckId);
          currentDeckConfig = _database.select(
            'SELECT key, usn, mtime_secs, val FROM config WHERE key = ?',
            ['curDeck'],
          );
          for (final deck in decks) {
            decksToRemove.add(Deck.fromProto(deck.toProto()));
            if (deck.id != Int64.ONE) {
              deckGraves[deck.id] = hasDeckDeletionGrave(deck.id);
            }
            final rows = _database.select(
              'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
              'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
              'flags, data FROM cards WHERE did = ?',
              [_toSqlInt64(deck.id)],
            );
            final deckCards = rows.map(_cardFromRow).toList(growable: false);
            if (deck.kind is FilteredDeckKind) {
              cardsToReturn.addAll(deckCards);
            } else {
              cardsToDelete.addAll(deckCards);
              for (final card in deckCards) {
                revlogs.addAll(_revlogStorage.getRevlogEntriesForCard(card.id));
                cardGraves[card.id] = hasDeletionGrave(card.id, note: false);
              }
            }
            final prefix = '_deck_${deck.id}_';
            auxConfigRows.addAll(
              _database.select(
                'SELECT key, usn, mtime_secs, val FROM config '
                'WHERE substr(key, 1, length(?)) = ?',
                [prefix, prefix],
              ),
            );
          }
          final deletedNoteIds = cardsToDelete
              .map((card) => card.noteId)
              .toSet();
          final cardsByNote = await cardsOfNotes(deletedNoteIds);
          final notesById = await getNotesByIds(deletedNoteIds);
          for (final note in notesById) {
            final surviving = (cardsByNote[note.id] ?? const <Card>[]).any(
              (card) => !cardsToDelete.any((deleted) => deleted.id == card.id),
            );
            if (!surviving) {
              notes.add(copyNote(note));
              noteGraves[note.id] = hasDeletionGrave(note.id, note: true);
            }
          }
          prepared = true;
          return true;
        },
        apply: () async {
          for (final card in cardsToReturn) {
            await addOrUpdateCard(_cardRestoredFromFilteredDeck(card));
          }
          for (final entry in revlogs) {
            _revlogStorage.removeRevlogEntry(entry.id);
          }
          for (final card in cardsToDelete) {
            await removeCard(card.id);
            addDeletionGrave(card.id, note: false);
          }
          for (final note in notes) {
            await removeNote(note.id);
            addDeletionGrave(note.id, note: true);
          }
          for (final deck in decks) {
            final prefix = '_deck_${deck.id}_';
            _database.execute(
              'DELETE FROM config WHERE substr(key, 1, length(?)) = ?',
              [prefix, prefix],
            );
            if (deck.id == Int64.ONE) {
              final reset = Deck(
                id: deck.id,
                name: defaultDeckName,
                mtimeSecs: Int64(now ~/ 1000),
                usn: -1,
                common: deck.common,
                kind: deck.kind,
              );
              _deckStorage.updateDeck(reset);
            } else {
              _deckStorage.removeDeck(deck.id);
              addDeckDeletionGrave(deck.id);
            }
          }
          if (currentDeckWasDeleted) await selectDeck(Int64.ONE);
          _database.execute('UPDATE col SET mod = ?', [
            _toSqlInt64(afterMtime),
          ]);
        },
        undo: () async {
          if (currentDeckConfig.isEmpty) {
            _database.execute('DELETE FROM config WHERE key = ?', ['curDeck']);
          } else {
            final row = currentDeckConfig.single;
            _database.execute(
              'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) '
              'VALUES (?, ?, ?, ?)',
              [row['key'], row['usn'], row['mtime_secs'], row['val']],
            );
          }
          for (final row in auxConfigRows) {
            _database.execute(
              'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) '
              'VALUES (?, ?, ?, ?)',
              [row['key'], row['usn'], row['mtime_secs'], row['val']],
            );
          }
          for (final deck in decksToRemove) {
            _deckStorage.addOrUpdateDeckWithExistingId(deck);
            if (deck.id != Int64.ONE && deckGraves[deck.id] != true) {
              removeDeckDeletionGrave(deck.id);
            }
          }
          for (final card in cardsToReturn) {
            await addOrUpdateCard(card);
          }
          for (final note in notes) {
            await addOrUpdateNote(note);
            if (noteGraves[note.id] != true) {
              removeDeletionGrave(note.id, note: true);
            }
          }
          for (final card in cardsToDelete) {
            await addOrUpdateCard(card);
            if (cardGraves[card.id] != true) {
              removeDeletionGrave(card.id, note: false);
            }
          }
          for (final entry in revlogs) {
            restoreRevlogEntry(entry);
          }
          restoreCollectionModifiedAt(beforeMtime);
        },
        redo: () async {
          for (final card in cardsToReturn) {
            await addOrUpdateCard(_cardRestoredFromFilteredDeck(card));
          }
          for (final entry in revlogs) {
            _revlogStorage.removeRevlogEntry(entry.id);
          }
          for (final card in cardsToDelete) {
            await removeCard(card.id);
            addDeletionGrave(card.id, note: false);
          }
          for (final note in notes) {
            await removeNote(note.id);
            addDeletionGrave(note.id, note: true);
          }
          for (final deck in decks) {
            final prefix = '_deck_${deck.id}_';
            _database.execute(
              'DELETE FROM config WHERE substr(key, 1, length(?)) = ?',
              [prefix, prefix],
            );
            if (deck.id == Int64.ONE) {
              _deckStorage.updateDeck(
                Deck(
                  id: deck.id,
                  name: defaultDeckName,
                  mtimeSecs: Int64(now ~/ 1000),
                  usn: -1,
                  common: deck.common,
                  kind: deck.kind,
                ),
              );
            } else {
              _deckStorage.removeDeck(deck.id);
              addDeckDeletionGrave(deck.id);
            }
          }
          if (currentDeckWasDeleted) await selectDeck(Int64.ONE);
          restoreCollectionModifiedAt(afterMtime);
        },
        collectAdditionalChanges: () => [
          for (final deck in decks)
            if (deck.id != Int64.ONE && deckGraves[deck.id] != true)
              CollectionUndoChange.graveAdded(
                kind: CollectionUndoChangeKind.deck,
                objectId: deck.id,
                graveType: 2,
              ),
          for (final card in cardsToDelete)
            if (cardGraves[card.id] != true)
              CollectionUndoChange.graveAdded(
                kind: CollectionUndoChangeKind.card,
                objectId: card.id,
                graveType: 0,
              ),
          for (final note in notes)
            if (noteGraves[note.id] != true)
              CollectionUndoChange.graveAdded(
                kind: CollectionUndoChangeKind.note,
                objectId: note.id,
                graveType: 1,
              ),
        ],
        onCommitted: (generation) => committedUndoGeneration = generation,
      );
    } catch (error, stackTrace) {
      if (!prepared) Error.throwWithStackTrace(error, stackTrace);
      final applied =
          decks.every(
            (deck) => deck.id == Int64.ONE
                ? _deckStorage.getDeck(deck.id)?.name == defaultDeckName
                : _deckStorage.getDeck(deck.id) == null,
          ) &&
          cardsToDelete.every(
            (card) => _database.select('SELECT 1 FROM cards WHERE id = ?', [
              _toSqlInt64(card.id),
            ]).isEmpty,
          ) &&
          notes.every(
            (note) => _database.select('SELECT 1 FROM notes WHERE id = ?', [
              _toSqlInt64(note.id),
            ]).isEmpty,
          ) &&
          _readInt64(_database.select('SELECT mod FROM col').single['mod']) ==
              afterMtime;
      if (!applied || !_database.autocommit) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      // A flush can fail after SQLite commits. Retry persistence once after
      // reconciling the collection rows; never report a rollback in that case.
      try {
        await flushPendingWrites();
      } on Object {
        persistenceWarning = true;
      }
      committed = true;
    }
    // A Web driver may fail after SQLite committed. The operation and history
    // remain committed in that case; callers reconcile from the collection.
    if (!committed) throw StateError('deck removal was not committed');
    return DeckRemovalResult(
      deckName: target.name,
      cardsDeleted: cardsToDelete.length,
      collectionUndoGeneration: committedUndoGeneration,
      persistenceWarning: persistenceWarning,
    );
  }

  /// Unburies buried cards in [deckId] and all of its child decks.
  ///
  /// Queue restoration follows Core's card-type/due rule and does not touch
  /// suspended or otherwise active cards. The snapshots are retained as one
  /// undoable collection operation. A post-commit flush failure is reconciled
  /// as a committed result, like deck removal.
  Future<DeckUnburyResult> unburyDeck(Int64 deckId) async {
    final target = _deckStorage.getDeck(deckId);
    if (target == null) throw StateError('deck not found: $deckId');

    var deckIds = <Int64>[];
    var cardsBefore = <Card>[];
    var cardsAfter = <Card>[];
    var beforeMtime = Int64.ZERO;
    var afterMtime = Int64.ZERO;
    var committedUndoGeneration = collectionUndoGeneration;
    var persistenceWarning = false;
    var prepared = false;

    bool rowsMatchAfter() {
      for (final expected in cardsAfter) {
        final rows = _database.select(
          'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
          'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
          'flags, data FROM cards WHERE id = ?',
          [_toSqlInt64(expected.id)],
        );
        if (rows.isEmpty || _cardFromRow(rows.single).queue != expected.queue) {
          return false;
        }
      }
      return collectionModifiedAt == afterMtime;
    }

    try {
      final changed = await runUndoableCollectionOperation(
        operation: CollectionUndoOperation.unburyCards,
        captureSqlChanges: true,
        prepare: () async {
          final current = _deckStorage.getDeck(deckId);
          if (current == null) throw StateError('deck not found: $deckId');
          deckIds = _deckStorage.deckIdWithChildren(current);
          if (deckIds.isEmpty) return false;
          final placeholders = List.filled(deckIds.length, '?').join(', ');
          final rows = _database.select(
            'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
            'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
            'flags, data FROM cards WHERE did IN ($placeholders) AND queue IN (?, ?) '
            'ORDER BY id',
            [
              ...deckIds.map(_toSqlInt64),
              CardQueue.schedBuried.value,
              CardQueue.userBuried.value,
            ],
          );
          cardsBefore = rows.map(_cardFromRow).toList(growable: false);
          if (cardsBefore.isEmpty) return false;
          final now =
              _nowMillis?.call() ??
              DateTime.now().toUtc().millisecondsSinceEpoch;
          beforeMtime = collectionModifiedAt;
          afterMtime = Int64(now);
          final cardMtimeSecs = Int64(now ~/ 1000);
          cardsAfter = cardsBefore
              .map(
                (card) => _copyCardWithQueue(
                  card,
                  queue: _queueAfterUnbury(card),
                  mtimeSecs: cardMtimeSecs,
                  usn: -1,
                ),
              )
              .toList(growable: false);
          prepared = true;
          return true;
        },
        apply: () async {
          for (final card in cardsAfter) {
            await updateCard(card);
          }
          restoreCollectionModifiedAt(afterMtime);
        },
        undo: () async {
          for (final card in cardsBefore) {
            await updateCard(card);
          }
          restoreCollectionModifiedAt(beforeMtime);
        },
        redo: () async {
          for (final card in cardsAfter) {
            await updateCard(card);
          }
          restoreCollectionModifiedAt(afterMtime);
        },
        onCommitted: (generation) => committedUndoGeneration = generation,
      );
      if (!changed) {
        return DeckUnburyResult(
          deckName: target.name,
          cardsUnburied: 0,
          collectionUndoGeneration: collectionUndoGeneration,
        );
      }
    } catch (error, stackTrace) {
      if (!prepared) Error.throwWithStackTrace(error, stackTrace);
      if (!_database.autocommit || !rowsMatchAfter()) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      try {
        await flushPendingWrites();
      } on Object {
        persistenceWarning = true;
      }
    }

    return DeckUnburyResult(
      deckName: target.name,
      cardsUnburied: cardsAfter.length,
      collectionUndoGeneration: committedUndoGeneration,
      persistenceWarning: persistenceWarning,
    );
  }

  /// Returns cards from exactly [deckId] to their home decks using Core's
  /// filtered-deck queue restoration rules, as one undoable collection change.
  Future<FilteredDeckEmptyResult> emptyFilteredDeck(Int64 deckId) async {
    final target = _deckStorage.getDeck(deckId);
    if (target == null) throw StateError('deck not found: $deckId');
    if (target.kind is! FilteredDeckKind) {
      throw StateError('filtered deck required: $deckId');
    }

    var cardsBefore = <Card>[];
    var cardsAfter = <Card>[];
    var beforeMtime = Int64.ZERO;
    var afterMtime = Int64.ZERO;
    var committedUndoGeneration = collectionUndoGeneration;
    var persistenceWarning = false;
    var prepared = false;

    bool rowsMatchAfter() {
      for (final expected in cardsAfter) {
        final rows = _database.select(
          'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
          'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
          'flags, data FROM cards WHERE id = ?',
          [_toSqlInt64(expected.id)],
        );
        if (rows.isEmpty) return false;
        final actual = _cardFromRow(rows.single);
        if (actual.deckId != expected.deckId ||
            actual.queue != expected.queue ||
            actual.due != expected.due ||
            actual.originalDeckId != expected.originalDeckId ||
            actual.originalDue != expected.originalDue ||
            actual.mtimeSecs != expected.mtimeSecs ||
            actual.usn != expected.usn) {
          return false;
        }
      }
      return collectionModifiedAt == afterMtime;
    }

    try {
      final changed = await runUndoableCollectionOperation(
        operation: CollectionUndoOperation.emptyFilteredDeck,
        captureSqlChanges: true,
        prepare: () async {
          final current = _deckStorage.getDeck(deckId);
          if (current == null) throw StateError('deck not found: $deckId');
          if (current.kind is! FilteredDeckKind) {
            throw StateError('filtered deck required: $deckId');
          }
          final rows = _database.select(
            'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
            'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
            'flags, data FROM cards WHERE did = ? ORDER BY id',
            [_toSqlInt64(deckId)],
          );
          cardsBefore = rows.map(_cardFromRow).toList(growable: false);
          if (cardsBefore.isEmpty) return false;
          final now = Int64(
            _nowMillis?.call() ?? DateTime.now().toUtc().millisecondsSinceEpoch,
          );
          beforeMtime = collectionModifiedAt;
          afterMtime = now;
          final cardMtimeSecs = Int64(now.toInt() ~/ 1000);
          cardsAfter = cardsBefore
              .map(
                (card) => _copyCardAfterEmptyFilteredDeck(
                  card,
                  mtimeSecs: cardMtimeSecs,
                ),
              )
              .toList(growable: false);
          prepared = true;
          return true;
        },
        apply: () async {
          for (final card in cardsAfter) {
            await updateCard(card);
          }
          restoreCollectionModifiedAt(afterMtime);
        },
        undo: () async {
          for (final card in cardsBefore) {
            await updateCard(card);
          }
          restoreCollectionModifiedAt(beforeMtime);
        },
        redo: () async {
          for (final card in cardsAfter) {
            await updateCard(card);
          }
          restoreCollectionModifiedAt(afterMtime);
        },
        onCommitted: (generation) => committedUndoGeneration = generation,
      );
      if (!changed) {
        return FilteredDeckEmptyResult(
          deckName: target.name,
          cardsReturned: 0,
          collectionUndoGeneration: collectionUndoGeneration,
        );
      }
    } catch (error, stackTrace) {
      if (!prepared) Error.throwWithStackTrace(error, stackTrace);
      if (!_database.autocommit || !rowsMatchAfter()) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      try {
        await flushPendingWrites();
      } on Object {
        persistenceWarning = true;
      }
    }

    return FilteredDeckEmptyResult(
      deckName: target.name,
      cardsReturned: cardsAfter.length,
      collectionUndoGeneration: committedUndoGeneration,
      persistenceWarning: persistenceWarning,
    );
  }

  /// Creates/updates a filtered deck and moves matching cards into it.
  /// Search parsing, filtering, ordering and limits run on this collection.
  Future<FilteredDeckBuildResult> buildFilteredDeck(
    protoDeck.FilteredDeckForUpdate request,
  ) async {
    if (request.config.searchTerms.isEmpty ||
        request.config.searchTerms.length > 2) {
      throw ArgumentError('filtered decks require one or two search terms');
    }
    if (request.config.searchTerms.any((term) => term.limit > 0x7fffffff)) {
      throw RangeError('filtered deck limits must fit a signed Kotlin Int');
    }
    if (request.name.trim().isEmpty) {
      throw ArgumentError.value(request.name, 'name');
    }
    final name = normalizeDeckName(request.name.trim());

    var deckId = request.id;
    final existing = deckId == Int64.ZERO ? null : _deckStorage.getDeck(deckId);
    if (deckId != Int64.ZERO && existing == null) {
      throw StateError('deck not found: $deckId');
    }
    if (existing != null && existing.kind is! FilteredDeckKind) {
      throw StateError('filtered deck required: $deckId');
    }
    final conflictingDeck = _deckStorage.getAllDecks().any(
      (deck) =>
          deck.id != deckId &&
          compareUniCase(normalizeDeckName(deck.name), name) == 0,
    );
    if (conflictingDeck) {
      throw StateError('deck name already exists: $name');
    }

    final config = request.config.deepCopy();
    for (final term in config.searchTerms) {
      term.search = searchParser.normalizeSearch(term.search);
    }
    final previousDeck = existing;
    final previousCurrentDeckId = currentDeckId;
    final cardsBefore = <String, Card>{};
    final cardsAfter = <String, Card>{};
    final beforeMtime = collectionModifiedAt;
    var afterMtime = beforeMtime;
    Deck? deckAfter;
    FilteredDeckBuildResult? result;
    await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.buildFilteredDeck,
      captureSqlChanges: true,
      prepare: () async {
        if (existing != null) {
          final rows = _database.select(
            'SELECT id FROM cards WHERE did = ? ORDER BY id',
            [_toSqlInt64(existing.id)],
          );
          final cards = await getCardsByIds(
            rows.map((row) => _readInt64(row['id'])),
          );
          for (final card in cards) {
            cardsBefore[card.id.toString()] = card;
          }
        }
        return true;
      },
      apply: () async {
        final targetName = name;
        var targetDeck = existing;
        if (targetDeck == null) {
          final now = Int64(
            (_nowMillis?.call() ??
                    DateTime.now().toUtc().millisecondsSinceEpoch) ~/
                1000,
          );
          targetDeck = _deckStorage.addDeck(
            Deck(
              name: targetName,
              mtimeSecs: now,
              usn: -1,
              common: Deck.newNormal().common,
              kind: FilteredDeckKind(config),
            ),
          );
          deckId = targetDeck.id;
        } else {
          targetDeck = Deck(
            id: targetDeck.id,
            name: targetName,
            mtimeSecs: Int64(
              (_nowMillis?.call() ??
                      DateTime.now().toUtc().millisecondsSinceEpoch) ~/
                  1000,
            ),
            usn: -1,
            common: targetDeck.common,
            kind: FilteredDeckKind(config),
          );
          _deckStorage.updateDeck(targetDeck);
        }

        // Rebuilding first returns cards already in this deck to their home queues.
        final inDeck = await getCardsByIds(
          _database
              .select('SELECT id FROM cards WHERE did = ? ORDER BY id', [
                _toSqlInt64(deckId),
              ])
              .map((row) => Int64.parseInt(_readInt64(row['id']).toString())),
        );
        for (final card in inDeck) {
          cardsBefore.putIfAbsent(card.id.toString(), () => card);
          await updateCard(_cardRestoredFromFilteredDeck(card));
          cardsAfter[card.id.toString()] = _cardRestoredFromFilteredDeck(card);
        }

        var position = -100000;
        final searchTiming = _filteredSearchTiming();
        final movedIds = <String>{};
        for (final term in config.searchTerms) {
          final order = _filteredOrderSql(term.order.value, searchTiming);
          final query = term.search.trim().isEmpty
              ? '-is:suspended -is:buried'
              : '(${term.search}) -is:suspended -is:buried';
          final nodes = searchParser.parse(query);
          final node = nodes.length == 1
              ? nodes.single
              : searchParser.GroupNode(nodes);
          final compiledPlan = compileSearchSqlWithSort(
            node,
            timing: searchTiming,
            sortOrder: SearchSqlSortOrder.custom(
              '$order, fnvhash(c.id, c.mod) limit ${term.limit}',
            ),
          );
          // Core's `-deck:filtered` predicate means cards currently in any
          // filtered deck; this is stored directly in cards.odid, not a deck name.
          final plan = CompiledSearchSqlWithSort(
            search: CompiledSearchSql(
              sql: compiledPlan.search.sql.replaceFirst(
                RegExp(r' order by '),
                ' and c.odid = 0 order by ',
              ),
              arguments: compiledPlan.search.arguments,
              requiredTable: compiledPlan.search.requiredTable,
            ),
            preparationSql: compiledPlan.preparationSql,
          );
          final ids = await executeSearchPlan(plan);
          for (final bigId in ids) {
            final id = Int64.parseInt(bigId.toString());
            if (movedIds.contains(id.toString())) continue;
            final card = await getCard(id);
            if (card == null || card.originalDeckId != Int64.ZERO) continue;
            cardsBefore.putIfAbsent(card.id.toString(), () => card);
            movedIds.add(id.toString());
            final moved = Card.fromProto(
              card.toProto()
                ..deckId = deckId
                ..originalDeckId = card.deckId
                ..originalDue = card.due
                ..queue = config.reschedule
                    ? card.queue.value
                    : CardQueue.review.value
                // Core assigns search positions only to positive due values.
                ..due = card.due > 0 ? position : card.due
                ..usn = -1,
            );
            await updateCard(moved);
            cardsAfter[id.toString()] = moved;
            position++;
          }
        }
        if (movedIds.isEmpty && !request.allowEmpty) {
          throw StateError('filtered deck search returned no cards');
        }
        await selectDeck(deckId);
        deckAfter = _deckStorage.getDeck(deckId);
        afterMtime = Int64(
          (_nowMillis?.call() ??
                  DateTime.now().toUtc().millisecondsSinceEpoch) ~/
              1000,
        );
        restoreCollectionModifiedAt(afterMtime);
        result = FilteredDeckBuildResult(
          deckId: deckId,
          cardsMoved: movedIds.length,
        );
      },
      undo: () async {
        for (final card in cardsBefore.values) {
          await updateCard(card);
        }
        if (previousDeck == null) {
          _deckStorage.removeDeck(deckId);
        } else {
          _deckStorage.addOrUpdateDeckWithExistingId(previousDeck);
        }
        await selectDeck(previousCurrentDeckId);
        restoreCollectionModifiedAt(beforeMtime);
      },
      redo: () async {
        final deck = deckAfter;
        if (deck == null) throw StateError('filtered deck redo state missing');
        _deckStorage.addOrUpdateDeckWithExistingId(deck);
        for (final card in cardsAfter.values) {
          await updateCard(card);
        }
        await selectDeck(deck.id);
        restoreCollectionModifiedAt(afterMtime);
      },
    );
    return result!;
  }

  SearchSqlTiming _filteredSearchTiming() {
    final nowMillis =
        _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
    final fallbackNow = nowMillis ~/ 1000;
    late final SchedTimingToday timing;
    try {
      timing = timingTodayForNow(
        now: DateTime.fromMillisecondsSinceEpoch(nowMillis).toLocal(),
      );
    } on Object {
      // Small in-memory test collections may not contain Core's timing rows.
      timing = SchedTimingToday(
        now: fallbackNow,
        daysElapsed: fallbackNow ~/ 86400,
        nextDayAt: (fallbackNow ~/ 86400 + 1) * 86400,
      );
    }
    return SearchSqlTiming(
      daysElapsed: timing.daysElapsed,
      now: BigInt.from(timing.now),
      learnAheadSecs: _readConfigInt('collapseTime') ?? 1200,
      nextDayAt: BigInt.from(timing.nextDayAt),
    );
  }

  String _filteredOrderSql(int order, SearchSqlTiming timing) {
    final now = timing.now;
    final day = timing.daysElapsed;
    final nextDay = timing.nextDayAt!;
    final fsrsEnabled = readCollectionConfig('fsrs') == true;
    return switch (order) {
      0 => '(select max(id) from revlog where cid=c.id)',
      1 => 'random()',
      2 => 'c.ivl',
      3 => 'c.ivl desc',
      4 => 'c.lapses desc',
      5 => 'n.id, c.ord',
      6 =>
        '(case when c.due > 1000000000 then c.due else (c.due - $day) * 86400 + $now end), c.ord',
      7 => 'n.id desc, c.ord asc',
      8 when fsrsEnabled =>
        "extract_fsrs_retrievability(c.data, case when c.odue != 0 then c.odue else c.due end, c.ivl, $day, $nextDay, $now) asc",
      8 => 'fnvhash(c.id, c.mod)',
      9 when fsrsEnabled =>
        "extract_fsrs_retrievability(c.data, case when c.odue != 0 then c.odue else c.due end, c.ivl, $day, $nextDay, $now) desc",
      9 => 'fnvhash(c.id, c.mod)',
      10 =>
        "extract_fsrs_relative_retrievability(c.data, case when c.odue != 0 then c.odue else c.due end, c.ivl, $day, $nextDay, $now) asc",
      _ => throw ArgumentError.value(order, 'order'),
    };
  }

  /// Restores a review log entry with its original 64-bit ID.
  void restoreRevlogEntry(RevlogEntry entry) {
    _throwIfExternalCollectionUndoOperationIsActive();
    final restored = _revlogStorage.addRevlogEntry(entry);
    if (restored == null) throw StateError('revlog ID is already in use');
  }

  /// Opens [location] through the chosen [driver] and applies collection
  /// connection pragmas before returning the database adapter.
  ///
  /// [nowMillis] overrides the clock used for generated note row IDs. It is
  /// intended for deterministic tests; callers should normally omit it.
  static Future<CollectionSqliteStorage> open({
    required CollectionSqliteDriver driver,
    required String location,
    CollectionSqliteOptions options = const CollectionSqliteOptions(),
    int Function()? nowMillis,
  }) async {
    CommonDatabase? database;
    try {
      final openedDatabase = await Future<CommonDatabase>.sync(
        () => driver.openDatabase(location),
      );
      database = openedDatabase;
      _registerCoreFieldIndexFunction(openedDatabase);
      registerProcessTextFunction(openedDatabase);
      registerFnvHashFunction(openedDatabase);
      registerCardDataFunctions(openedDatabase);
      registerFsrsVariableFunction(openedDatabase);
      registerFsrsRetrievabilityFunctions(openedDatabase);
      registerRegexFunctions(openedDatabase);
      registerUnicaseCollation(openedDatabase);
      openedDatabase.execute('pragma busy_timeout = 0');
      openedDatabase.execute('pragma locking_mode = exclusive');
      openedDatabase.execute('pragma page_size = 4096');
      openedDatabase.execute('pragma cache_size = -40960');
      openedDatabase.execute('pragma legacy_file_format = off');
      openedDatabase.execute('pragma journal_mode = wal');
      if (options.androidTempStore) {
        openedDatabase.execute('pragma temp_store = memory');
      }
      final configureConnection = options.configureConnection;
      if (configureConnection != null) {
        await Future<void>.sync(() => configureConnection(openedDatabase));
      }
      await Future<void>.sync(() => driver.flush?.call());
      return CollectionSqliteStorage._(
        openedDatabase,
        driver,
        nowMillis,
        options,
      );
    } catch (error, stackTrace) {
      try {
        database?.close();
      } catch (_) {
        // Keep the initialization failure as the observable error.
      }
      try {
        final mediaStorage = driver.mediaStorage;
        if (mediaStorage != null) {
          await Future<void>.sync(mediaStorage.close);
        }
      } catch (_) {
        // Preserve the initialization failure; callers can retry the open.
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

  /// Builds Core's due tree for scheduler-resolved timing and collection
  /// preferences. [daysElapsed] and [learnCutoff] are the same values Core
  /// passes to `SqliteStorage::due_counts()` for the requested timestamp.
  Future<protoDeck.DeckTreeNode> deckTree({
    required int daysElapsed,
    required int learnCutoff,
    bool browser = false,
    bool newCardsIgnoreReviewLimit = false,
    bool applyAllParentLimits = false,
  }) async {
    _requiredUnsigned(daysElapsed, 32, 'daysElapsed');
    _requiredUnsigned(learnCutoff, 32, 'learnCutoff');
    final dueCounts = <Int64, protoDeck.DeckTreeNode>{};
    final rows = _database.select(
      '''
SELECT did,
  sum(queue = 0) AS new_count,
  sum(queue = 2 AND due <= ?) AS review_count,
  sum(queue = 3 AND due <= ?) AS interday_learning,
  sum((queue = 1 AND due < ?) OR (queue = 4 AND due <= ?)) AS intraday_learning,
  count(1) AS total_cards
FROM cards
GROUP BY did
''',
      [daysElapsed, daysElapsed, learnCutoff, learnCutoff],
    );
    for (final row in rows) {
      final id = _readInt64(row['did']);
      final newCount = _requiredUnsigned(row['new_count'], 32, 'new_count');
      final reviewCount = _requiredUnsigned(
        row['review_count'],
        32,
        'review_count',
      );
      final interday = _requiredUnsigned(
        row['interday_learning'],
        32,
        'interday_learning',
      );
      final intraday = _requiredUnsigned(
        row['intraday_learning'],
        32,
        'intraday_learning',
      );
      dueCounts[id] = protoDeck.DeckTreeNode(
        deckId: id,
        newCount: newCount,
        reviewCount: reviewCount,
        learnCount: intraday + interday,
        intradayLearning: intraday,
        interdayLearningUncapped: interday,
        newUncapped: newCount,
        reviewUncapped: reviewCount,
        totalInDeck: _requiredUnsigned(row['total_cards'], 32, 'total_cards'),
      );
    }
    final orderedDecks = _deckStorage.getAllDecksInNameOrder();
    return buildCoreDeckTree(
      decksInNameOrder: orderedDecks,
      dueCountsByDeck: dueCounts,
      deckConfigs: _deckConfigStorage.getDeckConfigMap(),
      today: daysElapsed,
      defaultDeckIsEmpty: _database
          .select('SELECT 1 FROM cards WHERE did = 1 LIMIT 1')
          .isEmpty,
      browser: browser,
      newCardsIgnoreReviewLimit: newCardsIgnoreReviewLimit,
      applyAllParentLimits: applyAllParentLimits,
    );
  }

  /// Builds the current study deck tree using the collection's source
  /// scheduler settings and the current platform timezone.
  Future<protoDeck.DeckTreeNode> deckTreeForNow({DateTime? now}) async {
    final timing = timingTodayForNow(now: now);
    await _unburyIfDayRolledOver(timing.daysElapsed);
    final currentSecs = timing.now;
    final learnAhead = _readConfigInt('collapseTime') ?? 1200;
    return deckTree(
      daysElapsed: timing.daysElapsed,
      learnCutoff: (currentSecs + learnAhead).toUnsigned(32),
      newCardsIgnoreReviewLimit:
          _readConfigBool('newCardsIgnoreReviewLimit') ?? false,
      applyAllParentLimits: _readConfigBool('applyAllParentLimits') ?? false,
    );
  }

  /// Resolves scheduler timing from the collection's creation and rollover
  /// settings using [now] and the active platform timezone.
  SchedTimingToday timingTodayForNow({DateTime? now}) {
    final current = now ?? DateTime.now();
    final currentSecs = current.millisecondsSinceEpoch ~/ 1000;
    final metadata = _database.select('SELECT crt, conf FROM col').single;
    final creationSecs = _requiredSigned(metadata['crt'], 64, 'crt');
    final collectionConfig = _decodeJsonObjectOrEmpty(metadata['conf']);
    final schedulerVersion =
        _readConfigInt('schedVer') ??
        _optionalJsonInt(collectionConfig['schedVer']) ??
        1;
    final rollover = schedulerVersion == 2
        ? (_readConfigInt('rollover') ?? 4).clamp(0, 23)
        : null;
    final creationOffset =
        _readConfigInt('creationOffset') ??
        _optionalJsonInt(collectionConfig['creationOffset']);
    final minutesWest = -current.toLocal().timeZoneOffset.inMinutes;
    final timing = schedTimingToday(
      creationSecs: creationSecs,
      currentSecs: currentSecs,
      creationUtcOffsetMinutesWest: creationOffset,
      currentUtcOffsetMinutesWest: minutesWest,
      rolloverHour: rollover,
    );
    return timing;
  }

  /// Returns Core's configured current deck, or its source default ID.
  Int64 get currentDeckId => readCollectionConfigInt64('curDeck') ?? Int64.ONE;

  /// Returns the collection modification value exactly as stored by Core.
  Int64 get collectionModifiedAt =>
      _readInt64(_database.select('SELECT mod FROM col').single['mod']);

  /// Restores the exact stored collection modification value during undo.
  void restoreCollectionModifiedAt(Int64 value) {
    _throwIfExternalCollectionUndoOperationIsActive();
    _invalidateOperationHistoryAfterSubstoreWrite();
    _database.execute('UPDATE col SET mod = ?', [_toSqlInt64(value)]);
  }

  /// Records a Core-compatible card or note deletion grave.
  void addDeletionGrave(Int64 objectId, {required bool note}) {
    _throwIfExternalCollectionUndoOperationIsActive();
    _invalidateOperationHistoryAfterSubstoreWrite();
    _database.execute(
      'INSERT OR IGNORE INTO graves (oid, type, usn) VALUES (?, ?, -1)',
      [_toSqlInt64(objectId), note ? 1 : 0],
    );
  }

  /// Reports whether the collection already has this grave before an action.
  bool hasDeletionGrave(Int64 objectId, {required bool note}) =>
      _database.select('SELECT 1 FROM graves WHERE oid = ? AND type = ?', [
        _toSqlInt64(objectId),
        note ? 1 : 0,
      ]).isNotEmpty;

  /// Removes a deletion grave when an operation is undone.
  void removeDeletionGrave(Int64 objectId, {required bool note}) {
    _throwIfExternalCollectionUndoOperationIsActive();
    _invalidateOperationHistoryAfterSubstoreWrite();
    _database.execute('DELETE FROM graves WHERE oid = ? AND type = ?', [
      _toSqlInt64(objectId),
      note ? 1 : 0,
    ]);
  }

  /// Records a deleted deck using Core's distinct deck-grave type.
  void addDeckDeletionGrave(Int64 deckId) {
    _throwIfExternalCollectionUndoOperationIsActive();
    _invalidateOperationHistoryAfterSubstoreWrite();
    _database.execute(
      'INSERT OR IGNORE INTO graves (oid, type, usn) VALUES (?, 2, -1)',
      [_toSqlInt64(deckId)],
    );
  }

  /// Reports whether a deck deletion grave already existed.
  bool hasDeckDeletionGrave(Int64 deckId) => _database.select(
    'SELECT 1 FROM graves WHERE oid = ? AND type = 2',
    [_toSqlInt64(deckId)],
  ).isNotEmpty;

  /// Removes a deck grave when a deletion is undone.
  void removeDeckDeletionGrave(Int64 deckId) {
    _throwIfExternalCollectionUndoOperationIsActive();
    _invalidateOperationHistoryAfterSubstoreWrite();
    _database.execute('DELETE FROM graves WHERE oid = ? AND type = 2', [
      _toSqlInt64(deckId),
    ]);
  }

  /// Marks the collection as modified at [modifiedAtMillis].
  ///
  /// Higher-level collection operations use this alongside card or note row
  /// changes so the collection metadata reflects the committed operation.
  Future<void> updateCollectionModifiedAt(Int64 modifiedAtMillis) async {
    await _withExternalCollectionMutation(() {
      _database.execute('UPDATE col SET mod = ?', [
        _toSqlInt64(modifiedAtMillis),
      ]);
      discardExistingNoteUpdateUndoHistory();
    });
    await _flushIfAutocommit();
  }

  /// Selects [deckId], matching Core's non-undoable current-deck setting.
  Future<void> selectDeck(Int64 deckId) =>
      _writeConfigValue('curDeck', deckId.toString());

  /// Persists the reviewer or browser collapsed state of a deck.
  Future<void> setDeckCollapsed(
    Int64 deckId, {
    required bool collapsed,
    bool browser = false,
  }) async {
    await _withExternalCollectionMutation(() {
      final deck = _deckStorage.getDeck(deckId);
      if (deck == null) throw StateError('deck not found: $deckId');
      final common = deck.common.deepCopy();
      if (browser) {
        common.browserCollapsed = collapsed;
      } else {
        common.studyCollapsed = collapsed;
      }
      _deckStorage.updateDeck(
        Deck(
          id: deck.id,
          name: deck.name,
          mtimeSecs: Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          // Anki Core's client-side Collection.usn() returns -1. The update
          // path marks modified decks with that value before writing them.
          usn: -1,
          common: common,
          kind: deck.kind,
        ),
      );
    });
    await _flushIfAutocommit();
  }

  /// Returns today's custom-study extension defaults and uncapped queue counts.
  Future<CollectionCustomStudyLimitDefaults> customStudyLimitDefaults(
    Int64 deckId,
  ) async {
    final deck = _deckStorage.getDeck(deckId);
    if (deck == null) throw StateError('deck not found: $deckId');
    if (deck.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $deckId');
    }
    final tree = await deckTreeForNow();
    protoDeck.DeckTreeNode? find(protoDeck.DeckTreeNode node) {
      if (node.deckId == deckId) return node;
      for (final child in node.children) {
        final match = find(child);
        if (match != null) return match;
      }
      return null;
    }

    final node = find(tree);
    if (node == null) throw StateError('deck not found in tree: $deckId');
    var childrenNew = 0;
    var childrenReview = 0;
    void sumChildren(protoDeck.DeckTreeNode parent) {
      for (final child in parent.children) {
        childrenNew += child.newUncapped;
        childrenReview += child.reviewUncapped;
        sumChildren(child);
      }
    }

    sumChildren(node);
    final normal = (deck.kind as NormalDeckKind).value;
    return CollectionCustomStudyLimitDefaults(
      extendNew: normal.extendNew,
      extendReview: normal.extendReview,
      availableNew: node.newUncapped,
      availableReview: node.reviewUncapped,
      availableNewInChildren: childrenNew,
      availableReviewInChildren: childrenReview,
    );
  }

  /// Extends today's queue by changing studied-today counts, matching Core.
  Future<void> extendCustomStudyLimits(
    Int64 deckId, {
    int newDelta = 0,
    int reviewDelta = 0,
  }) async {
    if (newDelta < -0x80000000 ||
        newDelta > 0x7fffffff ||
        reviewDelta < -0x80000000 ||
        reviewDelta > 0x7fffffff) {
      throw RangeError('limit delta must fit in int32');
    }
    final selected = _deckStorage.getDeck(deckId);
    if (selected == null) throw StateError('deck not found: $deckId');
    if (selected.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $deckId');
    }
    if (newDelta == 0 && reviewDelta == 0) return;
    final today = timingTodayForNow().daysElapsed;
    final before = <Deck>[selected];
    if (_readConfigBool('applyAllParentLimits') ?? false) {
      final names = selected.name.split('::');
      for (var i = 1; i < names.length; i++) {
        final parent = _deckStorage.getDeckByName(names.take(i).join('\u001f'));
        if (parent != null) before.add(parent);
      }
    }
    final after = <Deck>[];
    for (final deck in before) {
      final common = deck.common.deepCopy();
      if (common.lastDayStudied != today) {
        common
          ..lastDayStudied = today
          ..newStudied = 0
          ..reviewStudied = 0;
      }
      common
        ..newStudied -= newDelta
        ..reviewStudied -= reviewDelta;
      var kind = deck.kind;
      if (deck.id == deckId && (newDelta > 0 || reviewDelta > 0)) {
        final normal = (deck.kind as NormalDeckKind).value.deepCopy();
        if (newDelta > 0) normal.extendNew = newDelta;
        if (reviewDelta > 0) normal.extendReview = reviewDelta;
        kind = NormalDeckKind(normal);
      }
      after.add(
        Deck(
          id: deck.id,
          name: deck.name,
          mtimeSecs: Int64(
            (_nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch) ~/
                1000,
          ),
          usn: -1,
          common: common,
          kind: kind,
        ),
      );
    }
    await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.extendStudyLimits,
      captureSqlChanges: true,
      apply: () async {
        for (final deck in after) {
          _deckStorage.updateDeck(deck);
        }
      },
      undo: () async {
        for (final deck in before) {
          _deckStorage.updateDeck(deck);
        }
      },
      redo: () async {
        for (final deck in after) {
          _deckStorage.updateDeck(deck);
        }
      },
    );
  }

  /// Updates a normal deck's description using an undoable collection write.
  /// The deck ID is kept as an [Int64] so Web callers do not narrow it.
  Future<void> updateDeckDescription(
    Int64 deckId, {
    required String description,
    required bool markdownDescription,
  }) async {
    final before = _deckStorage.getDeck(deckId);
    if (before == null) throw StateError('deck not found: $deckId');
    if (before.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $deckId');
    }

    final normal = (before.kind as NormalDeckKind).value.deepCopy()
      ..description = description
      ..markdownDescription = markdownDescription;
    final after = Deck(
      id: before.id,
      name: before.name,
      mtimeSecs: Int64(
        (_nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000,
      ),
      usn: -1,
      common: before.common,
      kind: NormalDeckKind(normal),
    );

    await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.changeDeckDescription,
      captureSqlChanges: true,
      apply: () async => _deckStorage.updateDeck(after),
      undo: () async => _deckStorage.updateDeck(before),
      redo: () async => _deckStorage.updateDeck(after),
    );
  }

  /// Updates the two daily limits in the normal deck's existing preset.
  ///
  /// Presets are shared by decks, so every deck using this configuration sees
  /// the change. Other configuration values are retained and the mutation is
  /// atomic and available through collection undo/redo.
  Future<void> updateDeckDailyLimits(
    Int64 deckId, {
    required int newPerDay,
    required int reviewsPerDay,
  }) async {
    _validateDailyLimit('newPerDay', newPerDay);
    _validateDailyLimit('reviewsPerDay', reviewsPerDay);

    final deck = _deckStorage.getDeck(deckId);
    if (deck == null) throw StateError('deck not found: $deckId');
    final configId = deck.configId;
    if (configId == null) throw StateError('normal deck required: $deckId');
    final before = _deckConfigStorage.getDeckConfig(configId);
    if (before == null) {
      throw StateError('missing deck configuration: $configId');
    }
    if (before.inner.newPerDay == newPerDay &&
        before.inner.reviewsPerDay == reviewsPerDay) {
      // A preceding save may have committed the in-memory/SQLite change but
      // failed while flushing it to the host. Let retrying Save flush that
      // already-committed value without creating another undo step.
      if (_database.autocommit) await _flush();
      return;
    }

    final after = DeckConfig(
      id: before.id,
      name: before.name,
      mtimeSecs: Int64(
        (_nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000,
      ),
      usn: -1,
      inner: before.inner.deepCopy()
        ..newPerDay = newPerDay
        ..reviewsPerDay = reviewsPerDay,
    );
    await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.changeDeckDailyLimits,
      captureSqlChanges: true,
      apply: () async => _deckConfigStorage.updateDeckConfig(after),
      undo: () async => _deckConfigStorage.updateDeckConfig(before),
      redo: () async => _deckConfigStorage.updateDeckConfig(after),
    );
  }

  static void _validateDailyLimit(String name, int value) {
    if (value < 0 || value > 9999) {
      throw ArgumentError.value(value, name, 'must be between 0 and 9999');
    }
  }

  /// Returns whether [deckId] or any of its descendants contains buried cards.
  bool deckHasBuriedCards(Int64 deckId) {
    final deck = _deckStorage.getDeck(deckId);
    if (deck == null) return false;
    final ids = _deckStorage.deckIdWithChildren(deck);
    final placeholders = List.filled(ids.length, '?').join(',');
    return _database
        .select(
          'SELECT 1 FROM cards WHERE did IN ($placeholders) AND queue IN (-2, -3) LIMIT 1',
          ids.map(_toSqlInt64).toList(growable: false),
        )
        .isNotEmpty;
  }

  /// Creates missing normal-deck ancestors and returns the requested deck.
  Future<Deck> getOrCreateNormalDeck(String name) async {
    final normalized = normalizeDeckName(name);
    final components = normalized.split('::');
    var result = _deckStorage.getDeck(Int64.ONE);
    for (var count = 1; count <= components.length; count++) {
      final currentName = components.take(count).join('::');
      final nativeName = currentName.replaceAll('::', '\x1f');
      final existingId = _deckStorage.getDeckId(nativeName);
      if (existingId != null) {
        result = _deckStorage.getDeck(existingId);
        continue;
      }
      final added = await _withExternalCollectionMutation(() {
        final initial = Deck.newNormal();
        return _deckStorage.addDeck(
          Deck(name: currentName, common: initial.common, kind: initial.kind),
        );
      });
      result = added;
      await _flushIfAutocommit();
    }
    if (result == null) throw StateError('default deck not found');
    return result;
  }

  /// Gets or creates a normal deck through the shared collection journal.
  /// Newly created ancestors and the requested deck are replayed with their
  /// original IDs; requesting an existing path is a no-op journal step.
  Future<Deck> getOrCreateNormalDeckUndoable(String name) async {
    final normalized = normalizeDeckName(name);
    if (normalized.isEmpty) throw ArgumentError.value(name, 'name');
    final requestedId = _deckStorage.getDeckId(
      normalized.replaceAll('::', '\x1f'),
    );
    Deck? result = requestedId == null
        ? null
        : _deckStorage.getDeck(requestedId);
    await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.createDeck,
      captureSqlChanges: true,
      prepare: () async {
        final components = normalized.split('::');
        var prefix = '';
        for (final component in components) {
          prefix = prefix.isEmpty ? component : '$prefix::$component';
          if (_deckStorage.getDeckId(prefix.replaceAll('::', '\x1f')) == null) {
            return true;
          }
        }
        return false;
      },
      apply: () async => result = await getOrCreateNormalDeck(normalized),
    );
    final resolved =
        result ??
        _deckStorage.getDeck(
          _deckStorage.getDeckId(normalized.replaceAll('::', '\x1f')) ??
              Int64.ZERO,
        );
    if (resolved == null) throw StateError('created deck was not found');
    return resolved;
  }

  /// Creates a child under [parentId], rejecting missing or filtered parents
  /// and an already-existing normalized child name. The child is selected
  /// after it has been persisted, matching Deck Picker creation behavior.
  Future<Deck> createSubdeck(Int64 parentId, String subdeckName) async {
    if (subdeckName.isEmpty || subdeckName.replaceAll('"', '').isEmpty) {
      throw ArgumentError.value(subdeckName, 'subdeckName');
    }
    final parent = _deckStorage.getDeck(parentId);
    if (parent == null) throw StateError('deck not found: $parentId');
    if (parent.kind is FilteredDeckKind) {
      throw StateError('normal deck required: $parentId');
    }

    String validate() {
      final currentParent = _deckStorage.getDeck(parentId);
      if (currentParent == null) throw StateError('deck not found: $parentId');
      if (currentParent.kind is FilteredDeckKind) {
        throw StateError('normal deck required: $parentId');
      }

      var fullName = normalizeDeckName(currentParent.name);
      final parentComponents = fullName.split('::');
      for (var count = 1; count < parentComponents.length; count++) {
        final ancestorName = parentComponents.take(count).join('::');
        final ancestorId = _deckStorage.getDeckId(
          ancestorName.replaceAll('::', '\x1f'),
        );
        final ancestor = ancestorId == null
            ? null
            : _deckStorage.getDeck(ancestorId);
        if (ancestor?.kind case FilteredDeckKind()) {
          throw StateError('filtered deck ancestor: $ancestorName');
        }
      }

      final childComponents = subdeckName
          .split('::')
          .map(normalizeDeckName)
          .toList(growable: false);
      for (var index = 0; index < childComponents.length; index++) {
        final candidateName = normalizeDeckName(
          '$fullName::${childComponents[index]}',
        );
        final candidateId = _deckStorage.getDeckId(
          candidateName.replaceAll('::', '\x1f'),
        );
        final candidate = candidateId == null
            ? null
            : _deckStorage.getDeck(candidateId);
        final isFinalComponent = index == childComponents.length - 1;
        if (candidate != null && !isFinalComponent) {
          if (candidate.kind is FilteredDeckKind) {
            throw StateError('filtered deck ancestor: ${candidate.name}');
          }
          // Core carries the stored parent spelling forward when a path
          // component resolves case-insensitively to an existing deck.
          fullName = candidate.name;
        } else if (candidate != null) {
          throw StateError('deck already exists: $candidateName');
        } else {
          fullName = candidateName;
        }
      }

      return fullName;
    }

    var fullName = validate();
    late Deck child;
    var createdDecks = <Deck>[];
    var previousCurrentDeckId = currentDeckId;
    final originalIds = <Int64>{};
    final committed = await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.createDeck,
      captureSqlChanges: true,
      prepare: () async {
        fullName = validate();
        previousCurrentDeckId = currentDeckId;
        originalIds.addAll(_deckStorage.getAllDecks().map((deck) => deck.id));
        return true;
      },
      apply: () async {
        child = await getOrCreateNormalDeck(fullName);
        createdDecks = _deckStorage
            .getAllDecks()
            .where((deck) => !originalIds.contains(deck.id))
            .toList(growable: false);
        await selectDeck(child.id);
      },
      undo: () async {
        for (final deck in createdDecks.reversed) {
          _deckStorage.removeDeck(deck.id);
        }
        await selectDeck(previousCurrentDeckId);
      },
      redo: () async {
        for (final deck in createdDecks) {
          _deckStorage.addOrUpdateDeckWithExistingId(deck);
        }
        await selectDeck(child.id);
      },
    );
    if (!committed) throw StateError('subdeck creation was not committed');
    return child;
  }

  /// Renames a deck and its descendants, preserving their IDs and payloads.
  /// Returns false when the normalized target name is already the current name.
  /// The operation is atomic so a duplicate or filtered-ancestor failure does
  /// not leave partially renamed descendants or newly-created parent decks.
  Future<bool> renameDeck(Int64 deckId, String newName) async {
    if (newName.trim().isEmpty) throw ArgumentError.value(newName, 'newName');
    final sourceDeck = _deckStorage.getDeck(deckId);
    if (sourceDeck == null) throw StateError('deck not found: $deckId');

    final normalizedName = normalizeDeckName(newName);
    final sourceDecks = _deckStorage.deckWithChildren(deckId);
    final movedIds = sourceDecks.map((deck) => deck.id).toSet();
    final currentName = normalizeDeckName(sourceDeck.name);
    if (normalizedName == currentName) {
      await _flush();
      return false;
    }
    final targetComponents = normalizedName.split('::');
    final sourceComponents = currentName.split('::');
    if (targetComponents.length > sourceComponents.length &&
        compareUniCase(
              targetComponents.take(sourceComponents.length).join('::'),
              currentName,
            ) ==
            0) {
      throw StateError('cannot rename a deck into its own hierarchy');
    }

    final allDecks = _deckStorage.getAllDecksInNameOrder();
    final renamedNames = <String>[];
    for (final deck in sourceDecks) {
      final suffix = deck.name == sourceDeck.name
          ? ''
          : deck.name.substring(sourceDeck.name.length);
      renamedNames.add('$normalizedName$suffix');
    }
    if (renamedNames.toSet().length != renamedNames.length) {
      throw StateError('duplicate deck name');
    }
    final namesById = {for (final deck in allDecks) deck.id: deck.name};
    for (var index = 0; index < renamedNames.length; index++) {
      final existingId = _deckStorage.getDeckId(
        renamedNames[index].replaceAll('::', '\x1f'),
      );
      if (existingId != null &&
          (!movedIds.contains(existingId) ||
              namesById[existingId] != sourceDecks[index].name)) {
        throw StateError('duplicate deck name: ${renamedNames[index]}');
      }
    }

    final components = normalizedName.split('::');
    var ancestorName = '';
    for (final component in components.take(components.length - 1)) {
      ancestorName = ancestorName.isEmpty
          ? component
          : '$ancestorName::$component';
      final ancestorId = _deckStorage.getDeckId(
        ancestorName.replaceAll('::', '\x1f'),
      );
      if (ancestorId != null &&
          _deckStorage.getDeck(ancestorId)?.kind is FilteredDeckKind) {
        throw StateError('cannot rename a deck under a filtered deck');
      }
    }

    await runUndoableCollectionOperation(
      operation: CollectionUndoOperation.renameDeck,
      captureSqlChanges: true,
      apply: () async {
        var ancestorName = '';
        for (final component in components.take(components.length - 1)) {
          ancestorName = ancestorName.isEmpty
              ? component
              : '$ancestorName::$component';
          final nativeName = ancestorName.replaceAll('::', '\x1f');
          if (_deckStorage.getDeckId(nativeName) == null) {
            final initial = Deck.newNormal();
            _deckStorage.addDeck(
              Deck(
                name: ancestorName,
                common: initial.common,
                kind: initial.kind,
              ),
            );
          }
        }
        for (var index = 0; index < sourceDecks.length; index++) {
          final deck = sourceDecks[index];
          _deckStorage.updateDeck(
            Deck(
              id: deck.id,
              name: renamedNames[index],
              mtimeSecs: Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000),
              usn: -1,
              common: deck.common,
              kind: deck.kind,
            ),
          );
        }
      },
    );
    return true;
  }

  Future<void> _unburyIfDayRolledOver(
    int today,
  ) => _withExternalCollectionMutation(() async {
    final lastUnburied = _readConfigInt('lastUnburied') ?? 0;
    if (!(lastUnburied < today || today + 7 < lastUnburied)) return;
    _database.execute('begin');
    try {
      _database.execute('''
UPDATE cards
SET queue = CASE
  WHEN type = 0 THEN 0
  WHEN type = 2 THEN 2
  WHEN type IN (1, 3) THEN CASE WHEN due > 1000000000 THEN 1 ELSE 3 END
  ELSE queue
END
WHERE queue IN (-2, -3)
''');
      _database.execute(
        'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) VALUES (?, -1, ?, ?)',
        [
          'lastUnburied',
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          utf8.encode(jsonEncode(today)),
        ],
      );
      _database.execute('commit');
      discardExistingNoteUpdateUndoHistory();
      await _flush();
    } catch (error, stackTrace) {
      try {
        _database.execute('rollback');
      } catch (_) {
        // Preserve the unbury failure.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  });

  int? _readConfigInt(String key) {
    final rows = _database.select('SELECT val FROM config WHERE key = ?', [
      key,
    ]);
    if (rows.isEmpty) return null;
    final value = _decodeJsonValue(rows.single['val']);
    return value is int ? value : null;
  }

  /// Reads an integer JSON config value without routing it through a JS number.
  Int64? _readConfigInt64(String key) {
    final rows = _database.select('SELECT val FROM config WHERE key = ?', [
      key,
    ]);
    if (rows.isEmpty) return null;
    final value = utf8.decode(rows.single['val'] as List<int>).trim();
    if (!RegExp(r'^-?(?:0|[1-9][0-9]*)$').hasMatch(value)) return null;
    try {
      return Int64.parseInt(value);
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  Future<void> _writeConfigValue(String key, String encodedJson) async {
    await _withExternalCollectionMutation(() {
      _writeConfigValueSync(key, encodedJson);
      discardExistingNoteUpdateUndoHistory();
    });
    await _flushIfAutocommit();
  }

  void _writeConfigValueSync(String key, String encodedJson) {
    _database.execute(
      'INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) VALUES (?, -1, ?, ?)',
      [
        key,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        utf8.encode(encodedJson),
      ],
    );
  }

  bool? _readConfigBool(String key) {
    final rows = _database.select('SELECT val FROM config WHERE key = ?', [
      key,
    ]);
    if (rows.isEmpty) return null;
    final value = _decodeJsonValue(rows.single['val']);
    return value is bool ? value : null;
  }

  static Map<String, Object?> _decodeJsonObjectOrEmpty(Object? value) {
    if (value == null || value == '') return const {};
    final decoded = _decodeJsonValue(value);
    if (decoded is Map<String, Object?>) return decoded;
    throw const FormatException('Invalid collection config JSON object');
  }

  static Object? _decodeJsonValue(Object? value) {
    final text = switch (value) {
      String string => string,
      Uint8List bytes => utf8.decode(bytes),
      List<int> bytes => utf8.decode(bytes),
      _ => throw FormatException('Invalid JSON config value: $value'),
    };
    return jsonDecode(text);
  }

  static int? _optionalJsonInt(Object? value) => value is int ? value : null;

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

  /// Returns the union of note tags in [deckId] and its descendants.
  ///
  /// The host combines these with the collection tag table to preserve
  /// TagsDialog's custom-study selection and hierarchy behavior.
  Future<List<String>> tagsForDeck(Int64 deckId) async {
    final deck = _deckStorage.getDeck(deckId);
    if (deck == null) throw StateError('deck not found: $deckId');
    final ids = _deckStorage.deckIdWithChildren(deck).toList(growable: false);
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = _database.select(
      'SELECT n.tags FROM cards c JOIN notes n ON n.id = c.nid '
      'WHERE c.did IN ($placeholders) ORDER BY n.id, c.id',
      ids.map(_toSqlInt64).toList(growable: false),
    );
    final tagsOnNotes = <String>{};
    for (final row in rows) {
      tagsOnNotes.addAll(_splitTags(row['tags'] as String));
    }
    return tagsOnNotes.toList(growable: false);
  }

  /// Returns stored cards in the requested ID order, omitting missing IDs.
  ///
  /// IDs are chunked to stay below conservative SQLite bind-parameter limits.
  Future<List<Card>> getCardsByIds(Iterable<CardId> ids) async {
    final orderedIds = ids.toList(growable: false);
    if (orderedIds.isEmpty) return const [];
    final cardsById = <String, Card>{};
    for (var start = 0; start < orderedIds.length; start += 500) {
      final chunk = orderedIds.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = _database.select(
        'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
        'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
        'flags, data FROM cards WHERE id IN ($placeholders)',
        chunk.map(_toSqlInt64).toList(growable: false),
      );
      for (final row in rows) {
        final card = _cardFromRow(row);
        cardsById[card.id.toString()] = card;
      }
    }
    return [
      for (final id in orderedIds)
        if (cardsById[id.toString()] case final card?) card,
    ];
  }

  /// Generates Notes or Cards text for the whole collection or a selected
  /// deck and its descendants. This only returns memory text; file delivery is
  /// the responsibility of the platform host.
  Future<CollectionTextExportResult> exportText({
    required bool cards,
    required CollectionTextExportOptions options,
    Int64? deckId,
  }) async {
    final deckIds = deckId == null
        ? null
        : _deckStorage
              .deckIdWithChildren(
                _deckStorage.getDeck(deckId) ??
                    (throw StateError('deck not found: $deckId')),
              )
              .toList();
    if (deckIds != null && deckIds.isEmpty) {
      return generateCollectionTextExport(
        cards: cards,
        options: options,
        notes: const [],
        cardRecords: const [],
      );
    }
    final selectedCards = _database
        .select(
          deckIds == null
              ? 'SELECT id FROM cards ORDER BY id'
              : 'SELECT id FROM cards WHERE did IN (${List.filled(deckIds.length, '?').join(',')}) ORDER BY id',
          deckIds?.map(_toSqlInt64).toList() ?? const [],
        )
        .map((row) => _readInt64(row.columnAt(0)))
        .toList();
    final cardValues = await getCardsByIds(selectedCards);
    final deckNames = {
      for (final deck in _deckStorage.getAllDecks()) deck.id: deck.name,
    };
    if (cards) {
      final noteValues = await getNotesByIds(
        cardValues.map((card) => card.noteId).toSet(),
      );
      final notesById = {for (final note in noteValues) note.id: note};
      final typeIds = noteValues
          .map((note) => NotetypeId(note.notetypeId))
          .toSet();
      final types = await getNotetypesByIds(typeIds);
      final typesById = {for (final type in types) type.id.value: type};
      const renderer = BrowserCardTemplateRenderer();
      final rendered = <CollectionTextExportCard>[];
      for (final card in cardValues) {
        final note = notesById[card.noteId];
        final type = note == null ? null : typesById[note.notetypeId];
        if (note == null || type == null) continue;
        final sides = renderer.render(
          note: note,
          card: card,
          notetype: type,
          deckName: deckNames[card.deckId] ?? '',
          useBrowserFormats: false,
          prettifyAv: false,
        );
        if (!sides.isAvailable) {
          throw StateError(
            'Unable to render card ${card.id}: ${sides.unavailableReason}',
          );
        }
        rendered.add(
          CollectionTextExportCard(
            id: card.id,
            question: exportTextField(sides.questionHtml!, options.includeHtml),
            answer: exportCardAnswer(sides.answerHtml!, options.includeHtml),
          ),
        );
      }
      return generateCollectionTextExport(
        cards: true,
        options: options,
        notes: const [],
        cardRecords: rendered,
      );
    }
    final noteIds = cardValues.map((card) => card.noteId).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    final notes = await getNotesByIds(noteIds);
    final noteDecks = <Int64, Int64>{};
    final allCardsByNote = await cardsOfNotes(noteIds);
    for (final entry in allCardsByNote.entries) {
      final noteCards = entry.value.toList()
        ..sort((a, b) => a.templateIdx.compareTo(b.templateIdx));
      if (noteCards.isNotEmpty) noteDecks[entry.key] = noteCards.first.deckId;
    }
    final types = await getNotetypesByIds(
      notes.map((note) => NotetypeId(note.notetypeId)).toSet(),
    );
    final typesById = {for (final type in types) type.id.value: type};
    final fieldColumnCount = types.fold<int>(
      0,
      (max, type) => type.fields.length > max ? type.fields.length : max,
    );
    final records = [
      for (final note in notes)
        CollectionTextExportNote(
          guid: note.guid,
          notetypeName: typesById[note.notetypeId]?.name ?? '',
          deckName: deckNames[noteDecks[note.id]] ?? '',
          fields: note.fields
              .map((field) => exportTextField(field, options.includeHtml))
              .toList(),
          tags: note.tags,
        ),
    ];
    return generateCollectionTextExport(
      cards: false,
      options: options,
      notes: records,
      cardRecords: const [],
      fieldColumnCount: fieldColumnCount,
    );
  }

  /// Updates all persisted scheduling fields for [card].
  Future<void> updateCard(Card card) async {
    await _withExternalCollectionMutation(() {
      _database.execute('''
      UPDATE cards SET nid = ?, did = ?, ord = ?, mod = ?, usn = ?,
        type = ?, queue = ?, due = ?, ivl = ?, factor = ?, reps = ?,
        lapses = ?, left = ?, odue = ?, odid = ?, flags = ?, data = ?
      WHERE id = ?
    ''', _cardValues(card)..add(_toSqlInt64(card.id)));
      if (_database.updatedRows > 0) discardExistingNoteUpdateUndoHistory();
    });
    await _flushIfAutocommit();
  }

  Future<CardId> addCard(Card card) async {
    final id = await _withExternalCollectionMutation(() {
      final inserted = _addCardSync(card);
      discardExistingNoteUpdateUndoHistory();
      return inserted;
    });
    await _flushIfAutocommit();
    return id;
  }

  CardId _addCardSync(Card card) {
    final values = _cardValues(card);
    final now = _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
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
    return id;
  }

  Future<bool> addCardIfUnique(Card card) async {
    final inserted = await _withExternalCollectionMutation(() {
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
      if (inserted) discardExistingNoteUpdateUndoHistory();
      return inserted;
    });
    await _flushIfAutocommit();
    return inserted;
  }

  Future<void> addOrUpdateCard(Card card) async {
    await _withExternalCollectionMutation(() {
      _database.execute(
        '''
      INSERT OR REPLACE INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
        [_toSqlInt64(card.id), ..._cardValues(card)],
      );
      if (_database.updatedRows > 0) discardExistingNoteUpdateUndoHistory();
    });
    await _flushIfAutocommit();
  }

  Future<void> removeCard(CardId id) async {
    await _withExternalCollectionMutation(() {
      _database.execute('DELETE FROM cards WHERE id = ?', [_toSqlInt64(id)]);
      if (_database.updatedRows > 0) discardExistingNoteUpdateUndoHistory();
    });
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

  /// Returns due learning and preview-repeat cards in the supplied active
  /// decks, preserving SQLite's natural query order.
  Future<List<IntradayLearningCandidate>> intradayLearningCandidates({
    required Iterable<Int64> activeDeckIds,
    required Int64 learnCutoffSecs,
  }) async {
    final deckIds = activeDeckIds.toList(growable: false);
    if (deckIds.isEmpty) return const [];

    // Deck IDs are typed integers, so their decimal literals are safe here and
    // avoid SQLite's bind-parameter limit for large active-deck sets.
    final deckIdList = deckIds.map((id) => id.toString()).join(', ');
    final rows = _database.select(
      'SELECT id, nid, due, cast(mod AS integer) AS mtime_secs, did, odid, reps '
      'FROM cards WHERE did IN ($deckIdList) '
      'AND queue IN (1, 4) AND due <= ?',
      [_toSqlInt64(learnCutoffSecs)],
    );
    return rows
        .map(
          (row) => IntradayLearningCandidate(
            id: _readInt64(row['id']),
            noteId: _readInt64(row['nid']),
            due: _optionalInt32(row['due']) ?? 0,
            mtimeSecs: _readInt64(row['mtime_secs']),
            currentDeckId: _readInt64(row['did']),
            originalDeckId: _readInt64(row['odid']),
            reps: _requiredUnsigned(row['reps'], 32, 'reps'),
          ),
        )
        .toList(growable: false);
  }

  /// Loads cards grouped by requested note IDs using bounded SQLite queries.
  /// Notes without cards are present with an empty list.
  Future<Map<NoteId, List<Card>>> cardsOfNotes(Iterable<NoteId> noteIds) async {
    final requestedIds = noteIds.toSet().toList(growable: false);
    if (requestedIds.isEmpty) return const {};
    final grouped = <NoteId, List<Card>>{
      for (final noteId in requestedIds) noteId: <Card>[],
    };
    for (var start = 0; start < requestedIds.length; start += 500) {
      final chunk = requestedIds.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = _database.select(
        'SELECT id, nid, did, ord, cast(mod AS integer), usn, type, queue, '
        'due, cast(ivl AS integer), factor, reps, lapses, left, odue, odid, '
        'flags, data FROM cards WHERE nid IN ($placeholders)',
        chunk.map(_toSqlInt64).toList(growable: false),
      );
      for (final row in rows) {
        final card = _cardFromRow(row);
        grouped[card.noteId]!.add(card);
      }
    }
    return Map.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<Card>.unmodifiable(entry.value),
    });
  }

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

  /// Returns stored notes in the requested ID order, omitting missing IDs.
  ///
  /// IDs are chunked to stay below conservative SQLite bind-parameter limits.
  Future<List<Note>> getNotesByIds(Iterable<NoteId> ids) async {
    final orderedIds = ids.toList(growable: false);
    if (orderedIds.isEmpty) return const [];
    final notesById = <String, Note>{};
    for (var start = 0; start < orderedIds.length; start += 500) {
      final chunk = orderedIds.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = _database.select(
        'SELECT id, guid, mid, mod, usn, tags, flds, cast(sfld AS text), csum '
        'FROM notes WHERE id IN ($placeholders)',
        chunk.map(_toSqlInt64).toList(growable: false),
      );
      for (final row in rows) {
        final note = _noteFromRow(row);
        notesById[note.id.toString()] = note;
      }
    }
    return [
      for (final id in orderedIds)
        if (notesById[id.toString()] case final note?) note,
    ];
  }

  /// Returns first fields for notes whose notetype and Core checksum match.
  ///
  /// This is the storage half of `Note.fieldsCheck()` duplicate detection;
  /// field normalization and exact text comparison remain in the model layer.
  List<NoteChecksumMatch> getNoteFieldsByChecksum(
    Int64 notetypeId,
    int checksum,
  ) => _database
      .select(
        'SELECT id, guid, mid, mod, usn, tags, flds, cast(sfld AS text), csum '
        'FROM notes WHERE mid = ? AND csum = ?',
        [_toSqlInt64(notetypeId), checksum.toUnsigned(32)],
      )
      .map((row) {
        final note = _noteFromRow(row);
        return NoteChecksumMatch(
          noteId: note.id,
          firstField: note.fields.first,
        );
      })
      .toList(growable: false);

  /// Loads stored note types for [ids], including their fields and templates.
  /// Each table is read in bounded batches, independent of the number of rows.
  Future<List<Notetype>> getNotetypesByIds(Iterable<NotetypeId> ids) async {
    final orderedIds = ids.toList(growable: false);
    if (orderedIds.isEmpty) return const [];
    final uniqueIds = orderedIds.toSet().toList(growable: false);
    final values = <String, Notetype>{};
    for (var start = 0; start < uniqueIds.length; start += 500) {
      final chunk = uniqueIds.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = _database.select(
        'SELECT id, name, mtime_secs, usn, config FROM notetypes '
        'WHERE id IN ($placeholders)',
        chunk.map((id) => _toSqlInt64(id.value)).toList(growable: false),
      );
      for (final row in rows) {
        final id = _readInt64(row.columnAt(0));
        final config = protoNotetype.Notetype_Config.fromBuffer(
          row.columnAt(4) as List<int>,
        );
        values[id.toString()] = Notetype(
          id: NotetypeId(id),
          name: row.columnAt(1) as String,
          mtimeSecs: _readInt64(row.columnAt(2)),
          usn: row.columnAt(3) as int,
          config: config,
        );
      }
    }
    if (values.isEmpty) return const [];
    final foundIds = values.values.map((value) => value.id).toList();
    for (var start = 0; start < foundIds.length; start += 500) {
      final chunk = foundIds.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final args = chunk.map((id) => _toSqlInt64(id.value)).toList();
      final fieldRows = _database.select(
        'SELECT ntid, ord, name, config FROM fields '
        'WHERE ntid IN ($placeholders) ORDER BY ntid, ord',
        args,
      );
      for (final row in fieldRows) {
        final notetype = values[_readInt64(row.columnAt(0)).toString()]!;
        notetype.fields.add(
          NoteField(
            ord: row.columnAt(1) as int,
            name: row.columnAt(2) as String,
            config: protoNotetype.Notetype_Field_Config.fromBuffer(
              row.columnAt(3) as List<int>,
            ),
          ),
        );
      }
      final templateRows = _database.select(
        'SELECT ntid, ord, name, mtime_secs, usn, config FROM templates '
        'WHERE ntid IN ($placeholders) ORDER BY ntid, ord',
        args,
      );
      for (final row in templateRows) {
        final notetype = values[_readInt64(row.columnAt(0)).toString()]!;
        notetype.templates.add(
          CardTemplate(
            ord: row.columnAt(1) as int,
            name: row.columnAt(2) as String,
            mtimeSecs: _readInt64(row.columnAt(3)),
            usn: row.columnAt(4) as int,
            config: protoNotetype.Notetype_Template_Config.fromBuffer(
              row.columnAt(5) as List<int>,
            ),
          ),
        );
      }
    }
    return [
      for (final id in orderedIds)
        if (values[id.toString()] case final notetype?) notetype,
    ];
  }

  /// Returns the IDs of every stored note type, including types without notes.
  Future<Set<NotetypeId>> getAllNotetypeIds() async => _database
      .select('SELECT id FROM notetypes')
      .map((row) => NotetypeId(_readInt64(row.columnAt(0))))
      .toSet();

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
    if (_portableSnapshotStarting) {
      throw StateError(
        'cannot begin a transaction during a collection snapshot',
      );
    }
    _executeCached('begin exclusive');
  }

  @override
  Future<void> executeBatch(String sql) async {
    // This escape hatch can mutate any collection table, so it invalidates
    // note-update history even when the caller's batch later fails.
    await _withExternalCollectionMutation(() {
      discardExistingNoteUpdateUndoHistory();
      _database.execute(sql);
    });
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
    if (_collectionUndoOperationDone != null) {
      throw StateError('cannot commit during an undoable operation');
    }
    if (_database.autocommit) return;
    _executeCached('commit');
    await _flush();
  }

  @override
  Future<void> rollback() async {
    if (_collectionUndoOperationDone != null) {
      throw StateError('cannot roll back during an undoable operation');
    }
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
    _closing = true;
    await _portableSnapshotDone?.future;
    await _searchQueue;
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
    if (!_mediaStorageClosed) {
      try {
        final mediaStorage = _driver.mediaStorage;
        if (mediaStorage != null) await Future<void>.sync(mediaStorage.close);
        _mediaStorageClosed = true;
      } catch (error, stackTrace) {
        closeError ??= error;
        closeStack ??= stackTrace;
      }
    }
    if (_connectionClosed && !flushFailed && _mediaStorageClosed) {
      _closed = true;
    }
    if (closeError != null) {
      Error.throwWithStackTrace(closeError, closeStack!);
    }
  }

  /// Alias for [close] for callers using disposable-resource terminology.
  Future<void> dispose() => close();

  Future<void> _flush() async {
    await Future<void>.sync(() => _driver.flush?.call());
  }

  Future<void> _flushIfAutocommit({
    bool preserveNoteUpdateHistory = false,
  }) async {
    if (!preserveNoteUpdateHistory) {
      discardExistingNoteUpdateUndoHistory();
    }
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
    _prepareCached(sql).execute();
  }

  CommonPreparedStatement _prepareCached(String sql) {
    var statement = _statementCache[sql];
    if (statement == null) {
      statement = _database.prepare(sql, persistent: true);
      if (_statementCache.length >= _preparedStatementCacheCapacity) {
        final oldestSql = _statementCache.keys.first;
        _statementCache.remove(oldestSql)!.close();
      }
      _statementCache[sql] = statement;
    }
    return statement;
  }
}

final class _CollectionUndoStep {
  _CollectionUndoStep({
    required this.label,
    required this.counter,
    required this.actions,
    this.noteUpdate,
    this.isCustom = false,
  });

  final String label;
  int counter;
  final List<_CollectionUndoAction> actions;
  final _ExistingNoteUpdateUndoStep? noteUpdate;
  final bool isCustom;

  Iterable<CollectionUndoChange> get changes =>
      actions.expand((action) => action.changes);
}

final class _CollectionUndoAction {
  const _CollectionUndoAction({
    this.undo,
    this.redo,
    this.undoChangeset,
    this.redoChangeset,
    this.changes = const [],
  });

  final Future<void> Function()? undo;
  final Future<void> Function()? redo;
  final Changeset? undoChangeset;
  final Changeset? redoChangeset;
  final List<CollectionUndoChange> changes;
}

final class _CollectionNoteStorageDatabase implements NoteStorageDatabase {
  const _CollectionNoteStorageDatabase(this.storage);

  final CollectionSqliteStorage storage;

  @override
  Int64 get lastInsertRowId {
    // CommonDatabase.lastInsertRowId is a Dart int. On JavaScript targets,
    // values above 2^53 can lose precision there, while SQLite result columns
    // preserve them as BigInt. Read the connection value through SQLite itself.
    final value = storage._database
        .select('SELECT last_insert_rowid()')
        .single
        .columnAt(0);
    return _readInt64(value);
  }

  @override
  NoteStorageStatement prepareCached(String sql) =>
      _CollectionNoteStorageStatement(storage, storage._prepareCached(sql));
}

final class _CollectionNoteStorageStatement implements NoteStorageStatement {
  const _CollectionNoteStorageStatement(this.storage, this.statement);

  final CollectionSqliteStorage storage;
  final CommonPreparedStatement statement;

  @override
  int execute(List<Object?> parameters) {
    storage._throwIfExternalCollectionUndoOperationIsActive();
    statement.execute([
      for (final parameter in parameters)
        if (parameter is Int64) _toSqlInt64(parameter) else parameter,
    ]);
    final updatedRows = storage._database.updatedRows;
    if (updatedRows > 0) storage.discardExistingNoteUpdateUndoHistory();
    return updatedRows;
  }
}

final class _DeckStorageDatabase
    implements
        DeckStorageDatabase,
        DeckConfigStorageDatabase,
        TagStorageDatabase,
        RevlogStorageDatabase {
  const _DeckStorageDatabase(this.storage, this.onWrite);

  final CollectionSqliteStorage storage;
  final void Function() onWrite;

  CommonDatabase get database => storage._database;

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
    storage._throwIfExternalCollectionUndoOperationIsActive();
    database.execute(sql, _sqliteParameters(parameters));
    final updatedRows = database.updatedRows;
    if (updatedRows > 0) onWrite();
    return updatedRows;
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

Card _cardRestoredFromFilteredDeck(Card card) {
  final queue = card.queue.value < 0
      ? card.queue
      : switch (card.ctype) {
          CardType.newCard => CardQueue.newCard,
          CardType.review => CardQueue.review,
          CardType.learn || CardType.relearn =>
            card.originalDue > 1000000000
                ? CardQueue.learn
                : CardQueue.dayLearn,
        };
  return Card.fromProto(
    card.toProto()
      ..deckId = card.originalDeckId
      ..due = card.originalDue
      ..queue = queue.value
      ..originalDeckId = Int64.ZERO
      ..originalDue = 0,
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

String _jsonInt64(Int64 value) => value.toString();

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

bool _semanticNoteDiffers(Note stored, Note edited) {
  if (stored.id != edited.id ||
      stored.guid != edited.guid ||
      stored.notetypeId != edited.notetypeId ||
      stored.usn != edited.usn ||
      !_sameStrings(stored.tags, edited.tags) ||
      !_sameStrings(stored.fields, edited.fields)) {
    return true;
  }
  // Core clears `sfld` and `csum` before comparing and ignores the incoming
  // mtime, which is synchronized to the stored timestamp before this check.
  return false;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _ExistingNoteUpdateUndoStep {
  _ExistingNoteUpdateUndoStep({
    required Note before,
    required Note after,
    required Iterable<Card> addedCards,
    required Iterable<String> addedTags,
    required this.collectionMtimeBefore,
    required this.collectionMtimeAfter,
    required this.nextCardPositionConfigBefore,
    required this.nextCardPositionConfigAfter,
    required this.operationTimestampSecs,
  }) : before = copyNote(before),
       after = copyNote(after),
       addedCards = List.unmodifiable(
         addedCards.map((card) => _copyCard(card)),
       ),
       addedTags = List.unmodifiable(addedTags);

  final Note before;
  final Note after;
  final List<Card> addedCards;
  final List<String> addedTags;
  final Int64 collectionMtimeBefore;
  final Int64 collectionMtimeAfter;
  final ExistingNoteUpdateConfigSnapshot? nextCardPositionConfigBefore;
  final ExistingNoteUpdateConfigSnapshot? nextCardPositionConfigAfter;
  final int operationTimestampSecs;

  bool get _containsOnlyNoteAndCollectionChanges =>
      addedCards.isEmpty &&
      addedTags.isEmpty &&
      _sameExistingNoteUpdateConfigSnapshot(
        nextCardPositionConfigBefore,
        nextCardPositionConfigAfter,
      );

  bool canCoalesceWith(
    _ExistingNoteUpdateUndoStep next, {
    required int coalesceTimeSecs,
  }) =>
      before.id == next.before.id &&
      coalesceTimeSecs - operationTimestampSecs < 60 &&
      _containsOnlyNoteAndCollectionChanges &&
      next._containsOnlyNoteAndCollectionChanges;

  _ExistingNoteUpdateUndoStep coalesceAfter(_ExistingNoteUpdateUndoStep next) =>
      _ExistingNoteUpdateUndoStep(
        before: before,
        after: next.after,
        addedCards: [...addedCards, ...next.addedCards],
        addedTags: [...addedTags, ...next.addedTags],
        collectionMtimeBefore: collectionMtimeBefore,
        collectionMtimeAfter: next.collectionMtimeAfter,
        nextCardPositionConfigBefore: nextCardPositionConfigBefore,
        nextCardPositionConfigAfter: next.nextCardPositionConfigAfter,
        operationTimestampSecs: operationTimestampSecs,
      );
}

bool _sameExistingNoteUpdateConfigSnapshot(
  ExistingNoteUpdateConfigSnapshot? left,
  ExistingNoteUpdateConfigSnapshot? right,
) {
  if (identical(left, right)) return true;
  if (left == null || right == null) return false;
  if (left.key != right.key ||
      left.usn != right.usn ||
      left.mtimeSecs != right.mtimeSecs ||
      left.value.length != right.value.length) {
    return false;
  }
  for (var index = 0; index < left.value.length; index++) {
    if (left.value[index] != right.value[index]) return false;
  }
  return true;
}

Card _copyCard(Card card) => Card(
  id: card.id,
  noteId: card.noteId,
  deckId: card.deckId,
  templateIdx: card.templateIdx,
  mtimeSecs: card.mtimeSecs,
  usn: card.usn,
  ctype: card.ctype,
  queue: card.queue,
  due: card.due,
  interval: card.interval,
  easeFactorRaw: card.easeFactorRaw,
  reps: card.reps,
  lapses: card.lapses,
  remainingStepsRaw: card.remainingStepsRaw,
  originalDue: card.originalDue,
  originalDeckId: card.originalDeckId,
  flags: card.flags,
  originalPosition: card.originalPosition,
  memoryState: card.memoryState,
  desiredRetention: card.desiredRetention,
  decay: card.decay,
  lastReviewTimeSecs: card.lastReviewTimeSecs,
  customData: card.customData,
);

CardQueue _queueAfterUnbury(Card card) => switch (card.ctype) {
  CardType.newCard => CardQueue.newCard,
  CardType.review => CardQueue.review,
  CardType.learn || CardType.relearn =>
    isUnixEpochTimestamp(card.due) ? CardQueue.learn : CardQueue.dayLearn,
};

Card _copyCardAfterEmptyFilteredDeck(Card card, {required Int64 mtimeSecs}) {
  var deckId = card.deckId;
  var due = card.due;
  var queue = card.queue;
  if (card.originalDeckId != Int64.ZERO) {
    deckId = card.originalDeckId;
    if (card.originalDue != 0) due = card.originalDue;
    if (queue.value >= 0) {
      queue = switch (card.ctype) {
        CardType.newCard => CardQueue.newCard,
        CardType.review => CardQueue.review,
        CardType.learn || CardType.relearn =>
          isUnixEpochTimestamp(due) ? CardQueue.learn : CardQueue.dayLearn,
      };
    }
  }
  return Card(
    id: card.id,
    noteId: card.noteId,
    deckId: deckId,
    templateIdx: card.templateIdx,
    mtimeSecs: mtimeSecs,
    usn: -1,
    ctype: card.ctype,
    queue: queue,
    due: due,
    interval: card.interval,
    easeFactorRaw: card.easeFactorRaw,
    reps: card.reps,
    lapses: card.lapses,
    remainingStepsRaw: card.remainingStepsRaw,
    originalDue: 0,
    originalDeckId: Int64.ZERO,
    flags: card.flags,
    originalPosition: card.originalPosition,
    memoryState: card.memoryState,
    desiredRetention: card.desiredRetention,
    decay: card.decay,
    lastReviewTimeSecs: card.lastReviewTimeSecs,
    customData: card.customData,
  );
}

Card _copyCardWithQueue(
  Card card, {
  required CardQueue queue,
  required Int64 mtimeSecs,
  required int usn,
}) => Card(
  id: card.id,
  noteId: card.noteId,
  deckId: card.deckId,
  templateIdx: card.templateIdx,
  mtimeSecs: mtimeSecs,
  usn: usn,
  ctype: card.ctype,
  queue: queue,
  due: card.due,
  interval: card.interval,
  easeFactorRaw: card.easeFactorRaw,
  reps: card.reps,
  lapses: card.lapses,
  remainingStepsRaw: card.remainingStepsRaw,
  originalDue: card.originalDue,
  originalDeckId: card.originalDeckId,
  flags: card.flags,
  originalPosition: card.originalPosition,
  memoryState: card.memoryState,
  desiredRetention: card.desiredRetention,
  decay: card.decay,
  lastReviewTimeSecs: card.lastReviewTimeSecs,
  customData: card.customData,
);
