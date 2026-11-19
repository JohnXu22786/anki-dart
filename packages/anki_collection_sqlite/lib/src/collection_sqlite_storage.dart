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
import 'package:anki_backend_protocol/anki/collection.pb.dart'
    as protoCollection;
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:fixnum/fixnum.dart';
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

part 'legacy_collection_migrations.dart';

const _preparedStatementCacheCapacity = 50;
final _collectionUndoOperationZoneKey = Object();
final _externalCollectionMutationZoneKey = Object();

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
  CollectionSqliteStorage._(this._database, this._driver, this._nowMillis);

  final CommonDatabase _database;
  final CollectionSqliteDriver _driver;
  final int Function()? _nowMillis;
  final Map<String, CommonPreparedStatement> _statementCache = {};
  Future<void> _searchQueue = Future<void>.value();
  Future<void> _existingNoteUpdateQueue = Future<void>.value();
  final List<_ExistingNoteUpdateUndoStep> _noteUpdateUndoSteps = [];
  final List<_ExistingNoteUpdateUndoStep> _noteUpdateRedoSteps = [];
  int _noteUpdateUndoCounter = 0;
  int _noteUpdateHistoryGeneration = 0;
  final List<_CollectionUndoStep> _collectionUndoSteps = [];
  final List<_CollectionUndoStep> _collectionRedoSteps = [];
  int _collectionUndoExternalMutationGeneration = 0;
  bool _preservingCollectionUndoHistory = false;
  int _collectionUndoGeneration = 0;
  Completer<void>? _collectionUndoOperationDone;
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
  /// retains a bounded history for this operation only. It is not a generic
  /// collection undo/redo stack.
  Future<ExistingNoteUpdateResult> updateExistingNote(Note edited) =>
      _serializeNoteUpdate(() async {
        late ExistingNoteUpdateResult result;
        late int operationTimeMillis;
        late int historyGenerationAtStart;
        final operationDone = await _acquireCollectionUndoOperation();
        _noteUpdateRedoSteps.clear();
        _noteUpdateUndoCounter++;
        historyGenerationAtStart = _noteUpdateHistoryGeneration;
        _preservingCollectionUndoHistory = true;
        try {
          operationTimeMillis =
              _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
          result = await runZoned(
            () => _updateExistingNote(
              edited,
              operationTimeMillis: operationTimeMillis,
            ),
            zoneValues: {_collectionUndoOperationZoneKey: this},
          );
        } catch (_) {
          discardExistingNoteUpdateUndoHistory();
          rethrow;
        } finally {
          _preservingCollectionUndoHistory = false;
          _releaseCollectionUndoOperation(operationDone);
        }
        if (result.changed) {
          _collectionUndoSteps.clear();
          _collectionRedoSteps.clear();
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
          try {
            await _flushIfAutocommit(preserveNoteUpdateHistory: true);
          } catch (_) {
            discardExistingNoteUpdateUndoHistory();
            rethrow;
          }
          if (_noteUpdateHistoryGeneration != historyGenerationAtStart) {
            return result;
          }
          final coalesceTimeSecs =
              (_nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch) ~/
              1000;
          if (_noteUpdateUndoSteps.isNotEmpty &&
              _noteUpdateUndoSteps.last.canCoalesceWith(
                step,
                coalesceTimeSecs: coalesceTimeSecs,
              )) {
            _noteUpdateUndoSteps[_noteUpdateUndoSteps.length - 1] =
                _noteUpdateUndoSteps.last.coalesceAfter(step);
          } else {
            _noteUpdateUndoSteps.add(step);
            if (_noteUpdateUndoSteps.length > 30) {
              _noteUpdateUndoSteps.removeAt(0);
            }
          }
        }
        return result;
      });

  /// Status for this storage's existing-note-update history only.
  ExistingNoteUpdateUndoStatus get existingNoteUpdateUndoStatus =>
      ExistingNoteUpdateUndoStatus(
        canUndo: _noteUpdateUndoSteps.isNotEmpty,
        canRedo: _noteUpdateRedoSteps.isNotEmpty,
        lastStep: _noteUpdateUndoCounter,
      );

  /// Invalidates the scoped history after direct substore writes or a caller
  /// transaction that changes collection state outside this adapter.
  void discardExistingNoteUpdateUndoHistory() {
    if (identical(Zone.current[_collectionUndoOperationZoneKey], this)) return;
    _clearExistingNoteUpdateUndoHistory();
    if (_preservingCollectionUndoHistory) {
      _collectionUndoExternalMutationGeneration++;
    }
    _collectionUndoSteps.clear();
    _collectionRedoSteps.clear();
    _collectionUndoGeneration++;
  }

  void _clearExistingNoteUpdateUndoHistory() {
    _noteUpdateHistoryGeneration++;
    _noteUpdateUndoSteps.clear();
    _noteUpdateRedoSteps.clear();
  }

  void _invalidateOperationHistoryAfterSubstoreWrite() {
    discardExistingNoteUpdateUndoHistory();
  }

  /// Reverts the latest successful [updateExistingNote] operation.
  Future<void> undoLastExistingNoteUpdate() => _serializeNoteUpdate(
    () => _withCollectionUndoOperation(() async {
      if (_noteUpdateUndoSteps.isEmpty) {
        throw StateError('no existing-note update to undo');
      }
      _noteUpdateUndoCounter++;
      final step = _noteUpdateUndoSteps.removeLast();
      _preservingCollectionUndoHistory = true;
      try {
        runZoned(
          () => _applyExistingNoteUpdateUndoStep(step, undo: true),
          zoneValues: {_collectionUndoOperationZoneKey: this},
        );
        _noteUpdateRedoSteps.add(step);
        await _flushIfAutocommit(preserveNoteUpdateHistory: true);
      } catch (_) {
        discardExistingNoteUpdateUndoHistory();
        rethrow;
      } finally {
        _preservingCollectionUndoHistory = false;
      }
    }),
  );

  /// Reapplies the latest undone [updateExistingNote] operation.
  Future<void> redoLastExistingNoteUpdate() => _serializeNoteUpdate(
    () => _withCollectionUndoOperation(() async {
      if (_noteUpdateRedoSteps.isEmpty) {
        throw StateError('no existing-note update to redo');
      }
      _noteUpdateUndoCounter++;
      final step = _noteUpdateRedoSteps.removeLast();
      _preservingCollectionUndoHistory = true;
      try {
        runZoned(
          () => _applyExistingNoteUpdateUndoStep(step, undo: false),
          zoneValues: {_collectionUndoOperationZoneKey: this},
        );
        _noteUpdateUndoSteps.add(step);
        await _flushIfAutocommit(preserveNoteUpdateHistory: true);
      } catch (_) {
        discardExistingNoteUpdateUndoHistory();
        rethrow;
      } finally {
        _preservingCollectionUndoHistory = false;
      }
    }),
  );

  Future<T> _withCollectionUndoOperation<T>(
    Future<T> Function() operation,
  ) async {
    final operationDone = await _acquireCollectionUndoOperation();
    try {
      return await operation();
    } finally {
      _releaseCollectionUndoOperation(operationDone);
    }
  }

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
  int get collectionUndoGeneration => _collectionUndoGeneration;

  /// Commits one collection operation and retains its exact inverse in the
  /// same bounded, process-local history used by Card Browser bulk actions.
  Future<bool> runUndoableCollectionOperation({
    Future<bool> Function()? prepare,
    required Future<void> Function() apply,
    required Future<void> Function() undo,
    required Future<void> Function() redo,
    void Function(int generation)? onCommitted,
  }) async {
    final operationDone = await _acquireCollectionUndoOperation();
    try {
      await beginExclusive();
      final externalMutationGeneration =
          _collectionUndoExternalMutationGeneration;
      _preservingCollectionUndoHistory = true;
      late final bool prepared;
      try {
        prepared = await runZoned(() async {
          if (prepare != null && !await prepare()) {
            _executeCached('rollback');
            return false;
          }
          await apply();
          _executeCached('commit');
          // Bulk operations supersede the editor's narrower undo history
          // while retaining the just-committed collection operation.
          _clearExistingNoteUpdateUndoHistory();
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
        _preservingCollectionUndoHistory = false;
      }
      if (!prepared) return false;
      if (externalMutationGeneration ==
          _collectionUndoExternalMutationGeneration) {
        _collectionRedoSteps.clear();
        _collectionUndoSteps.add(_CollectionUndoStep(undo: undo, redo: redo));
        if (_collectionUndoSteps.length > 30) _collectionUndoSteps.removeAt(0);
      }
      _collectionUndoGeneration++;
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
      try {
        await _replayCollectionOperation(step.undo);
      } catch (_) {
        if (externalMutationGeneration ==
            _collectionUndoExternalMutationGeneration) {
          _collectionUndoSteps.add(step);
        }
        rethrow;
      }
      if (externalMutationGeneration ==
          _collectionUndoExternalMutationGeneration) {
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
    _preservingCollectionUndoHistory = true;
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
    } finally {
      _preservingCollectionUndoHistory = false;
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
      try {
        await _replayCollectionOperation(step.redo);
      } catch (_) {
        if (externalMutationGeneration ==
            _collectionUndoExternalMutationGeneration) {
          _collectionRedoSteps.add(step);
        }
        rethrow;
      }
      if (externalMutationGeneration ==
          _collectionUndoExternalMutationGeneration) {
        _collectionUndoSteps.add(step);
      }
      _collectionUndoGeneration++;
      await _flushAfterCommittedUndoRedo();
    } finally {
      _releaseCollectionUndoOperation(operationDone);
    }
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
      return CollectionSqliteStorage._(database, driver, nowMillis);
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

    await _withExternalCollectionMutation(() async {
      _database.execute('begin');
      try {
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
        _database.execute('commit');
      } catch (_) {
        if (!_database.autocommit) _database.execute('rollback');
        rethrow;
      }
    });
    await _flushIfAutocommit(preserveNoteUpdateHistory: true);
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
  const _CollectionUndoStep({required this.undo, required this.redo});

  final Future<void> Function() undo;
  final Future<void> Function() redo;
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
