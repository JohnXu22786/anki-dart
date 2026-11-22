// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui
//
// Source-derived from rslib/src/dbcheck.rs in Anki Core at
// e64c6b1aee3e8d668fb8bbe084beada8e070d985.

part of 'collection_sqlite_storage.dart';

/// Ordered stages emitted by Anki Core's collection database check.
enum DatabaseCheckStage { integrity, optimize, cards, notes, history }

/// Progress produced by the shared collection database check.
final class DatabaseCheckProgress {
  const DatabaseCheckProgress(this.stage, {this.current = 0, this.total = 0});

  final DatabaseCheckStage stage;
  final int current;
  final int total;
}

/// A repair run that was cancelled before its transaction committed.
final class DatabaseCheckCancelled implements Exception {
  const DatabaseCheckCancelled();

  @override
  String toString() => 'Database check cancelled';
}

/// Repair counts returned by the shared collection database check.
final class DatabaseCheckResult {
  const DatabaseCheckResult({
    required this.orphanedCardsRemoved,
    required this.invalidCardPropertiesFixed,
    required this.newCardPositionsFixed,
    required this.missingDecksRecovered,
    required this.filteredCardsFixed,
    required this.revlogRowsFixed,
    required this.missingDeckNamesRecovered,
    required this.invalidIdsFixed,
    required this.cardLastReviewTimesFixed,
    required this.notesVisited,
    required this.noteFieldCountMismatches,
    required this.noteTagsFixed,
    required this.futureNoteModificationTimesFixed,
    required this.duplicateCardOrdinalsRemoved,
    required this.cardsWithoutTemplateRemoved,
    required this.notetypesRecovered,
    required this.invalidUtf8NotesFixed,
    required this.missingCardsRegenerated,
    required this.nextNewPositionFixed,
    required this.tagRegistryChanged,
    required this.unsupportedRepairCategories,
  });

  final int orphanedCardsRemoved;
  final int invalidCardPropertiesFixed;
  final int newCardPositionsFixed;
  final int missingDecksRecovered;
  final int filteredCardsFixed;
  final int revlogRowsFixed;
  final int missingDeckNamesRecovered;
  final int invalidIdsFixed;
  final int cardLastReviewTimesFixed;
  final int notesVisited;
  final int noteFieldCountMismatches;
  final int noteTagsFixed;
  final int futureNoteModificationTimesFixed;
  final int duplicateCardOrdinalsRemoved;
  final int cardsWithoutTemplateRemoved;
  final int notetypesRecovered;
  final int invalidUtf8NotesFixed;
  final int missingCardsRegenerated;
  final bool nextNewPositionFixed;
  final bool tagRegistryChanged;
  final List<String> unsupportedRepairCategories;

  /// Whether every supported Core repair category completed.
  bool get isComplete => unsupportedRepairCategories.isEmpty;
}

extension CollectionDatabaseCheck on CollectionSqliteStorage {
  /// Checks SQLite integrity, optimizes it, and repairs supported row classes.
  ///
  /// Serializes against collection mutations, repairs Core row classes in one
  /// transaction, and reports progress to the calling zone.
  Future<DatabaseCheckResult> checkDatabase({
    required void Function(DatabaseCheckProgress progress) onProgress,
    bool Function()? isCancelled,
  }) async {
    final callerZone = Zone.current;
    final operationDone = await _acquireCollectionUndoOperation();
    var committedChanges = false;
    try {
      final result = await runZoned(
        () => _runDatabaseCheck(
          onProgress: (progress) => callerZone.run(() => onProgress(progress)),
          isCancelled: isCancelled == null
              ? null
              : () => callerZone.run(isCancelled),
          onCommitted: (changed) => committedChanges = changed,
        ),
        zoneValues: {_collectionUndoOperationZoneKey: this},
      );
      if (_databaseCheckChanged(result)) {
        _invalidateOperationHistoryAfterSubstoreWrite();
      }
      return result;
    } catch (error, stackTrace) {
      if (committedChanges) {
        _invalidateOperationHistoryAfterSubstoreWrite();
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _releaseCollectionUndoOperation(operationDone);
    }
  }

  bool _databaseCheckChanged(DatabaseCheckResult result) =>
      result.orphanedCardsRemoved > 0 ||
      result.invalidCardPropertiesFixed > 0 ||
      result.newCardPositionsFixed > 0 ||
      result.missingDecksRecovered > 0 ||
      result.filteredCardsFixed > 0 ||
      result.revlogRowsFixed > 0 ||
      result.missingDeckNamesRecovered > 0 ||
      result.invalidIdsFixed > 0 ||
      result.cardLastReviewTimesFixed > 0 ||
      result.noteFieldCountMismatches > 0 ||
      result.noteTagsFixed > 0 ||
      result.futureNoteModificationTimesFixed > 0 ||
      result.duplicateCardOrdinalsRemoved > 0 ||
      result.cardsWithoutTemplateRemoved > 0 ||
      result.notetypesRecovered > 0 ||
      result.invalidUtf8NotesFixed > 0 ||
      result.missingCardsRegenerated > 0 ||
      result.nextNewPositionFixed ||
      result.tagRegistryChanged;

  Future<DatabaseCheckResult> _runDatabaseCheck({
    required void Function(DatabaseCheckProgress progress) onProgress,
    bool Function()? isCancelled,
    required void Function(bool changed) onCommitted,
  }) async {
    void checkCancelled() {
      if (isCancelled?.call() ?? false) throw const DatabaseCheckCancelled();
    }

    checkCancelled();
    onProgress(const DatabaseCheckProgress(DatabaseCheckStage.integrity));
    if (await quickCheckCorrupt()) {
      throw const CollectionIntegrityException('corrupt');
    }

    checkCancelled();
    onProgress(const DatabaseCheckProgress(DatabaseCheckStage.optimize));
    await optimize();

    checkCancelled();
    await beginExclusive();
    var committed = false;
    var orphanedCardsRemoved = 0;
    var invalidCardPropertiesFixed = 0;
    var newCardPositionsFixed = 0;
    var nextNewPositionFixed = false;
    var missingDecksRecovered = 0;
    var filteredCardsFixed = 0;
    var revlogRowsFixed = 0;
    var missingDeckNamesRecovered = 0;
    var invalidIdsFixed = 0;
    var cardLastReviewTimesFixed = 0;
    var notesVisited = 0;
    var noteFieldCountMismatches = 0;
    var noteTagsFixed = 0;
    var futureNoteModificationTimesFixed = 0;
    var duplicateCardOrdinalsRemoved = 0;
    var cardsWithoutTemplateRemoved = 0;
    var notetypesRecovered = 0;
    var invalidUtf8NotesFixed = 0;
    var missingCardsRegenerated = 0;
    var tagRegistryChanged = false;
    try {
      onProgress(const DatabaseCheckProgress(DatabaseCheckStage.cards));
      checkCancelled();
      final nowMillis =
          _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
      final nowSecs = nowMillis ~/ 1000;
      final today = timingTodayForNow(
        now: DateTime.fromMillisecondsSinceEpoch(nowMillis),
      ).daysElapsed;
      final cardFixCounts = _fixCardProperties(today: today, nowSecs: nowSecs);
      newCardPositionsFixed = cardFixCounts.$1;
      invalidCardPropertiesFixed = cardFixCounts.$2;
      _database.execute('''
        DELETE FROM cards
        WHERE NOT EXISTS (SELECT 1 FROM notes WHERE notes.id = cards.nid)
      ''');
      orphanedCardsRemoved = _database.updatedRows;

      missingDecksRecovered = _recoverMissingDeckIds(nowSecs);
      filteredCardsFixed = _fixFilteredCards();

      final noteRepairs = await _repairNoteFields(
        nowSecs: nowSecs,
        onProgress: onProgress,
        checkCancelled: checkCancelled,
      );
      notesVisited = noteRepairs.$1;
      noteFieldCountMismatches = noteRepairs.$2;
      noteTagsFixed = noteRepairs.$3;
      futureNoteModificationTimesFixed = noteRepairs.$4;
      duplicateCardOrdinalsRemoved = noteRepairs.$5;
      cardsWithoutTemplateRemoved = noteRepairs.$6;
      notetypesRecovered = noteRepairs.$7;
      invalidUtf8NotesFixed = noteRepairs.$8;
      tagRegistryChanged = noteRepairs.$9;
      missingCardsRegenerated = noteRepairs.$10;
      checkCancelled();

      onProgress(const DatabaseCheckProgress(DatabaseCheckStage.history));
      checkCancelled();
      revlogRowsFixed = _revlogStorage.fixRevlogProperties();
      checkCancelled();
      cardLastReviewTimesFixed = await _fixMissingCardLastReviewTimes(
        checkCancelled: checkCancelled,
      );
      checkCancelled();
      missingDeckNamesRecovered = _recoverMissingDeckNames(
        nowSecs,
        checkCancelled: checkCancelled,
      );
      checkCancelled();
      nextNewPositionFixed = _updateNextNewPosition(nowMillis);
      checkCancelled();
      invalidIdsFixed = _fixInvalidIds(
        nowMillis,
        checkCancelled: checkCancelled,
      );
      checkCancelled();
      final changed =
          orphanedCardsRemoved > 0 ||
          invalidCardPropertiesFixed > 0 ||
          newCardPositionsFixed > 0 ||
          missingDecksRecovered > 0 ||
          filteredCardsFixed > 0 ||
          revlogRowsFixed > 0 ||
          missingDeckNamesRecovered > 0 ||
          nextNewPositionFixed ||
          invalidIdsFixed > 0 ||
          cardLastReviewTimesFixed > 0 ||
          noteFieldCountMismatches > 0 ||
          noteTagsFixed > 0 ||
          futureNoteModificationTimesFixed > 0 ||
          duplicateCardOrdinalsRemoved > 0 ||
          cardsWithoutTemplateRemoved > 0 ||
          notetypesRecovered > 0 ||
          invalidUtf8NotesFixed > 0 ||
          tagRegistryChanged ||
          missingCardsRegenerated > 0;
      if (changed) {
        _database.execute('UPDATE col SET scm = ?', [
          _toSqlInt64(Int64(nowMillis)),
        ]);
      }
      checkCancelled();
      _database.execute('commit');
      committed = true;
      onCommitted(changed);
      await _flush();
    } catch (error, stackTrace) {
      if (!committed) {
        try {
          if (!_database.autocommit) {
            _database.execute('rollback');
            await _flush();
          }
        } catch (_) {
          // Preserve the repair error if rollback also fails.
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return DatabaseCheckResult(
      orphanedCardsRemoved: orphanedCardsRemoved,
      invalidCardPropertiesFixed: invalidCardPropertiesFixed,
      newCardPositionsFixed: newCardPositionsFixed,
      missingDecksRecovered: missingDecksRecovered,
      filteredCardsFixed: filteredCardsFixed,
      revlogRowsFixed: revlogRowsFixed,
      missingDeckNamesRecovered: missingDeckNamesRecovered,
      invalidIdsFixed: invalidIdsFixed,
      cardLastReviewTimesFixed: cardLastReviewTimesFixed,
      notesVisited: notesVisited,
      noteFieldCountMismatches: noteFieldCountMismatches,
      noteTagsFixed: noteTagsFixed,
      futureNoteModificationTimesFixed: futureNoteModificationTimesFixed,
      duplicateCardOrdinalsRemoved: duplicateCardOrdinalsRemoved,
      cardsWithoutTemplateRemoved: cardsWithoutTemplateRemoved,
      notetypesRecovered: notetypesRecovered,
      invalidUtf8NotesFixed: invalidUtf8NotesFixed,
      missingCardsRegenerated: missingCardsRegenerated,
      nextNewPositionFixed: nextNewPositionFixed,
      tagRegistryChanged: tagRegistryChanged,
      unsupportedRepairCategories: const [],
    );
  }

  Future<(int, int, int, int, int, int, int, int, bool, int)>
  _repairNoteFields({
    required int nowSecs,
    required void Function(DatabaseCheckProgress progress) onProgress,
    required void Function() checkCancelled,
  }) async {
    final rows = _database.select('SELECT id, mid FROM notes ORDER BY mid, id');
    final total = rows.length;
    final expandedTags = _tagStorage.expandedTags();
    final tagsBefore = _tagStorage.allTags();
    _tagStorage.clearAllTags();
    onProgress(
      DatabaseCheckProgress(DatabaseCheckStage.notes, current: 0, total: total),
    );
    final notetypeIds = rows.map((row) => NotetypeId(_readInt64(row['mid'])));
    final notetypes = {
      for (final notetype in await getNotetypesByIds(notetypeIds))
        notetype.id.value.toString(): notetype,
    };
    final notesByNotetype = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      notesByNotetype
          .putIfAbsent(_readInt64(row['mid']).toString(), () => [])
          .add(row);
    }
    var recoveredNotetypes = 0;
    var invalidUtf8Fixed = 0;
    var missingCardsRegenerated = 0;
    final notesWithInvalidUtf8Fixed = <String>{};
    for (final entry in notesByNotetype.entries) {
      checkCancelled();
      if (notetypes.containsKey(entry.key)) continue;
      final firstRow = entry.value.first;
      final firstNoteId = _readInt64(firstRow['id']);
      if (_fixInvalidUtf8InNote(firstNoteId)) {
        invalidUtf8Fixed++;
        notesWithInvalidUtf8Fixed.add(firstNoteId.toString());
      }
      final firstNote = await getNote(firstNoteId);
      if (firstNote == null) continue;
      final notetypeId = _readInt64(firstRow['mid']);
      final maxOrdinal = _database
          .select(
            'SELECT max(ord) FROM cards WHERE nid IN '
            '(SELECT id FROM notes WHERE mid = ?)',
            [_toSqlInt64(notetypeId)],
          )
          .single
          .columnAt(0);
      final notetype = _insertRecoveredNotetype(
        id: notetypeId,
        fieldCount: firstNote.fields.length,
        highestCardOrdinal: maxOrdinal == null
            ? -1
            : (maxOrdinal as num).toInt(),
        nowMillis: _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch,
      );
      notetypes[entry.key] = notetype;
      recoveredNotetypes++;
    }
    if (_database.select('SELECT 1 FROM notetypes LIMIT 1').isEmpty) {
      final nowMillis =
          _nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;
      _insertRecoveredNotetype(
        id: Int64(nowMillis),
        fieldCount: 2,
        highestCardOrdinal: -1,
        nowMillis: nowMillis,
      );
      recoveredNotetypes++;
    }
    var visited = 0;
    var fieldMismatches = 0;
    var noteTagsFixed = 0;
    var futureMtimes = 0;
    var duplicateOrdinals = 0;
    var cardsWithoutTemplate = 0;
    for (final row in rows) {
      checkCancelled();
      final noteId = _readInt64(row['id']);
      final notetypeId = _readInt64(row['mid']);
      final notetype = notetypes[notetypeId.toString()];
      if (!notesWithInvalidUtf8Fixed.contains(noteId.toString()) &&
          _fixInvalidUtf8InNote(noteId)) {
        invalidUtf8Fixed++;
        notesWithInvalidUtf8Fixed.add(noteId.toString());
      }
      final cardRepairs = _repairNoteCards(
        noteId,
        templateCount: notetype?.templates.length,
        isCloze: notetype?.isCloze ?? false,
        checkCancelled: checkCancelled,
      );
      duplicateOrdinals += cardRepairs.$1;
      cardsWithoutTemplate += cardRepairs.$2;
      final note = await getNote(noteId);
      if (note != null && notetype != null) {
        final originalTags = List<String>.of(note.tags);
        _canonifyEditedTags(note);
        final tagsChanged = !_sameStrings(originalTags, note.tags);
        if (tagsChanged) noteTagsFixed++;
        var changed =
            notesWithInvalidUtf8Fixed.contains(noteId.toString()) ||
            tagsChanged;
        if (notetype.fields.isNotEmpty &&
            note.fields.length != notetype.fields.length) {
          final fields = note.fieldsMut();
          if (fields.length > notetype.fields.length) {
            fields[notetype.fields.length - 1] = fields
                .skip(notetype.fields.length - 1)
                .join('; ');
            fields.removeRange(notetype.fields.length, fields.length);
          } else {
            fields.addAll(
              List.filled(notetype.fields.length - fields.length, ''),
            );
          }
          if (!note.tags.contains('db-check')) note.tags.add('db-check');
          fieldMismatches++;
          changed = true;
        }
        if (note.mtimeSecs > Int64(nowSecs)) {
          note.mtimeSecs = Int64(nowSecs);
          futureMtimes++;
          changed = true;
        }
        note.prepareForUpdate(
          notetype,
          normalizeText: _readConfigBool('normalizeNoteText') ?? false,
        );
        final existingCards = await allCardsOfNote(noteId);
        final missingOrdinals = notetype.templates.isEmpty && !notetype.isCloze
            ? const <int>[]
            : _requiredCardOrdinals(note, notetype, existingCards);
        if (missingOrdinals.isNotEmpty) {
          final targetDeck = _deckForGeneratedCard(
            existingCards,
            notetype.id.value,
          );
          final existingDue = _existingNewCardDue(existingCards);
          final duePosition = existingDue == null
              ? _nextGeneratedCardPosition(modifiedAtMillis: nowSecs * 1000)
              : null;
          for (final ordinal in missingOrdinals) {
            checkCancelled();
            final target =
                notetype.isCloze || ordinal >= notetype.templates.length
                ? Int64.ZERO
                : notetype.templates[ordinal].config.targetDeckId;
            final deckId = _deckForAdding(
              target == Int64.ZERO ? targetDeck : target,
            );
            final due = existingDue ?? _dueForDeck(duePosition!, deckId);
            _addCardSync(
              Card.newCard(
                noteId: note.id,
                templateIdx: ordinal,
                deckId: deckId,
                due: due,
              ),
            );
            missingCardsRegenerated++;
          }
          changed = true;
        }
        if (changed) {
          note.markModified(-1, mtimeSecs: nowSecs);
          note.prepareForUpdate(
            notetype,
            normalizeText: _readConfigBool('normalizeNoteText') ?? false,
          );
          _database.execute(
            '''
UPDATE notes
SET mod = ?, usn = ?, tags = ?, flds = ?, sfld = ?, csum = ?
WHERE id = ?
''',
            [
              _toSqlInt64(note.mtimeSecs),
              note.usn,
              note.tags.isEmpty ? '' : ' ${note.tags.join(' ')} ',
              note.fields.join('\x1f'),
              note.sortField,
              note.checksum,
              _toSqlInt64(note.id),
            ],
          );
        }
      }
      visited++;
      onProgress(
        DatabaseCheckProgress(
          DatabaseCheckStage.notes,
          current: visited,
          total: total,
        ),
      );
    }
    _tagStorage.restoreExpandedTags(expandedTags);
    final tagRegistryChanged = !_sameTags(tagsBefore, _tagStorage.allTags());
    return (
      visited,
      fieldMismatches,
      noteTagsFixed,
      futureMtimes,
      duplicateOrdinals,
      cardsWithoutTemplate,
      recoveredNotetypes,
      invalidUtf8Fixed,
      tagRegistryChanged,
      missingCardsRegenerated,
    );
  }

  bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  bool _sameTags(List<Tag> left, List<Tag> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  bool _fixInvalidUtf8InNote(Int64 noteId) {
    final rows = _database.select(
      'SELECT CAST(flds AS BLOB) AS flds, CAST(tags AS BLOB) AS tags '
      'FROM notes WHERE id = ?',
      [_toSqlInt64(noteId)],
    );
    if (rows.isEmpty) return false;
    final fieldsBytes = rows.single['flds'] as List<int>;
    final tagsBytes = rows.single['tags'] as List<int>;
    var invalid = false;
    String decode(List<int> bytes) {
      try {
        return utf8.decode(bytes);
      } on FormatException {
        invalid = true;
        return utf8.decode(bytes, allowMalformed: true);
      }
    }

    final fields = decode(fieldsBytes);
    final tags = decode(tagsBytes);
    if (!invalid) return false;
    _database.execute(
      'UPDATE notes SET flds = ?, sfld = ?, tags = ? WHERE id = ?',
      [fields, '', tags, _toSqlInt64(noteId)],
    );
    return _database.updatedRows > 0;
  }

  Notetype _insertRecoveredNotetype({
    required Int64 id,
    required int fieldCount,
    required int highestCardOrdinal,
    required int nowMillis,
  }) {
    var nextRandomId = BigInt.from(nowMillis) << 16;
    BigInt randomU64() {
      final value = nextRandomId;
      nextRandomId += BigInt.one;
      return value;
    }

    final stock = StockNotetypeFactory.basic(
      names: const StockNotetypeNames(
        basic: 'Basic',
        basicTyping: 'Basic (type in the answer)',
        basicReversed: 'Basic (and reversed card)',
        basicOptionalReversed: 'Basic (optional reversed card)',
        cloze: 'Cloze',
        frontField: 'Front',
        backField: 'Back',
        addReverseField: 'Add Reverse',
        textField: 'Text',
        backExtraField: 'Back Extra',
        commentsField: 'Comments',
        cardOne: 'Card 1',
        cardTwo: 'Card 2',
        imageOcclusion: 'Image Occlusion',
        occlusionsField: 'Occlusions',
        imageField: 'Image',
        headerField: 'Header',
        toggleMasks: 'Toggle Masks',
        errorLoadingImageOcclusion: 'Error loading image occlusion',
      ),
      randomU64: randomU64,
    );
    var nextFieldName = 3;
    while (stock.fields.length < fieldCount) {
      stock.fields.add(
        NoteField.newField('$nextFieldName', randomU64: randomU64),
      );
      nextFieldName++;
    }
    final question = stock.templates.single.config.qFormat;
    final answer = stock.templates.single.config.aFormat;
    while (stock.templates.length <= highestCardOrdinal) {
      stock.templates.add(
        CardTemplate.newTemplate(
          'Card ${stock.templates.length + 1}',
          question,
          answer,
          randomU64: randomU64,
        ),
      );
    }
    final stampSecs = Int64(nowMillis ~/ 1000);
    var name = 'db-check-$stampSecs-$fieldCount';
    while (_database.select('SELECT 1 FROM notetypes WHERE name = ?', [
      name,
    ]).isNotEmpty) {
      name += '+';
    }
    stock.name = name;
    stock.fixFieldNames();
    stock.fixTemplateNames();
    stock.ensureNamesUnique();
    stock.config.reqs.addAll(_stockTemplateRequirements(stock));
    final recovered = Notetype(
      id: NotetypeId(id),
      name: stock.name,
      mtimeSecs: stampSecs,
      usn: -1,
      fields: stock.fields,
      templates: stock.templates,
      config: stock.config,
    );
    _database.execute(
      'INSERT INTO notetypes (id, name, mtime_secs, usn, config) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        _toSqlInt64(id),
        recovered.name,
        _toSqlInt64(stampSecs),
        -1,
        recovered.config.writeToBuffer(),
      ],
    );
    for (var index = 0; index < recovered.fields.length; index++) {
      final field = recovered.fields[index];
      _database.execute(
        'INSERT INTO fields (ntid, ord, name, config) VALUES (?, ?, ?, ?)',
        [_toSqlInt64(id), index, field.name, field.config.writeToBuffer()],
      );
    }
    for (var index = 0; index < recovered.templates.length; index++) {
      final template = recovered.templates[index];
      _database.execute(
        'INSERT INTO templates '
        '(ntid, ord, name, mtime_secs, usn, config) VALUES (?, ?, ?, ?, ?, ?)',
        [
          _toSqlInt64(id),
          index,
          template.name,
          _toSqlInt64(stampSecs),
          -1,
          template.config.writeToBuffer(),
        ],
      );
    }
    return recovered;
  }

  (int, int) _repairNoteCards(
    Int64 noteId, {
    required int? templateCount,
    required bool isCloze,
    required void Function() checkCancelled,
  }) {
    var duplicateOrdinals = 0;
    var cardsWithoutTemplate = 0;
    final rows = _database.select(
      'SELECT id, ord FROM cards WHERE nid = ? ORDER BY id',
      [_toSqlInt64(noteId)],
    );
    final seen = <int>{};
    for (final row in rows) {
      checkCancelled();
      final ordinal = (row['ord'] as num).toInt();
      if (!seen.add(ordinal)) {
        duplicateOrdinals += _executeRepair('DELETE FROM cards WHERE id = ?', [
          _toSqlInt64(_readInt64(row['id'])),
        ]);
      }
    }

    if (templateCount == null || isCloze) {
      return (duplicateOrdinals, cardsWithoutTemplate);
    }
    final remainingRows = _database.select(
      'SELECT id, ord FROM cards WHERE nid = ? ORDER BY id',
      [_toSqlInt64(noteId)],
    );
    for (final row in remainingRows) {
      checkCancelled();
      final ordinal = (row['ord'] as num).toInt();
      if (ordinal >= templateCount) {
        cardsWithoutTemplate += _executeRepair(
          'DELETE FROM cards WHERE id = ?',
          [_toSqlInt64(_readInt64(row['id']))],
        );
      }
    }
    return (duplicateOrdinals, cardsWithoutTemplate);
  }

  (int, int) _fixCardProperties({required int today, required int nowSecs}) {
    // SQL is kept in the same order and with the same normalization rules as
    // Anki Core's storage/card/fix_*.sql files at the pinned source revision.
    final newCards = _executeRepair(
      '''
UPDATE cards
SET due = CASE WHEN type = 0 AND queue != 4 THEN 1000000 + due % 1000000 ELSE due END,
    mod = ?, usn = -1
WHERE due != CASE WHEN type = 0 AND queue != 4 THEN 1000000 + due % 1000000 ELSE due END
  AND due >= 1000000
''',
      [nowSecs],
    );
    var other = _executeRepair(
      '''
UPDATE cards
SET due = CASE WHEN queue = 2 AND due > 100000 THEN ? ELSE min(max(round(due), -2147483648), 2147483647) END,
    mod = ?, usn = -1
WHERE due != CASE WHEN queue = 2 AND due > 100000 THEN ? ELSE min(max(round(due), -2147483648), 2147483647) END
''',
      [today, nowSecs, today],
    );
    other += _executeRepair(
      '''
UPDATE cards
SET odue = CASE WHEN odue > 0 AND (type = 1 OR queue = 2) AND ? = 0 AND odid = 0
                THEN 0 ELSE min(max(round(odue), -2147483648), 2147483647) END,
    mod = ?, usn = -1
WHERE odue != CASE WHEN odue > 0 AND (type = 1 OR queue = 2) AND ? = 0 AND odid = 0
                   THEN 0 ELSE min(max(round(odue), -2147483648), 2147483647) END
''',
      [_isV1Scheduler ? 1 : 0, nowSecs, _isV1Scheduler ? 1 : 0],
    );
    other += _executeRepair(
      '''
UPDATE cards SET ivl = min(max(round(ivl), 0), 2147483647), mod = ?, usn = -1
WHERE ivl != min(max(round(ivl), 0), 2147483647)
''',
      [nowSecs],
    );
    other += _executeRepair(
      'UPDATE cards SET mod = cast(mod AS integer) WHERE mod != cast(mod AS integer)',
      const [],
    );
    other += _executeRepair(
      '''
UPDATE cards SET ord = max(0, min(30000, ord)), mod = ?, usn = -1
WHERE ord != max(0, min(30000, ord))
''',
      [nowSecs],
    );
    return (newCards, other);
  }

  bool get _isV1Scheduler => _readConfigInt('schedVer') == 1;

  int _executeRepair(String sql, List<Object?> parameters) {
    _database.execute(
      sql,
      parameters
          .map((value) => value is Int64 ? _toSqlInt64(value) : value)
          .toList(),
    );
    return _database.updatedRows;
  }

  int _recoverMissingDeckIds(int nowSecs) {
    var recovered = 0;
    for (final id in _deckStorage.missingDeckIds()) {
      _insertRepairDeck(
        Deck(
          id: id,
          name: 'recovered$id',
          mtimeSecs: Int64(nowSecs),
          usn: -1,
          common: protoDeck.Deck_Common(
            studyCollapsed: true,
            browserCollapsed: true,
          ),
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
        ),
        preserveId: true,
      );
      recovered++;
    }
    return recovered;
  }

  int _fixFilteredCards() {
    final rows = _database.select('''
SELECT id, did FROM cards WHERE odid > 0
''');
    // Resolve each candidate through DeckStorage; the kind column is a
    // protobuf blob and must not be inspected with SQL byte assumptions.
    var changed = 0;
    for (final row in rows) {
      final id = _readInt64(row['id']);
      final deckId = _readInt64(row['did']);
      if (_deckStorage.getDeck(deckId)?.kind case NormalDeckKind()) {
        changed += _executeRepair(
          'UPDATE cards SET odid = 0, odue = 0 WHERE id = ?',
          [_toSqlInt64(id)],
        );
      }
    }
    return changed;
  }

  int _recoverMissingDeckNames(
    int nowSecs, {
    required void Function() checkCancelled,
  }) {
    final names = _deckStorage.getAllDeckNames();
    var recovered = 0;
    Int64? deckIdForHumanName(String name) =>
        _deckStorage.getDeckId(name.replaceAll('::', '\x1f'));

    for (final (_, name) in names) {
      checkCancelled();
      final split = name.lastIndexOf('::');
      if (split < 0) continue;
      final immediateParent = name.substring(0, split);
      if (deckIdForHumanName(immediateParent) != null) continue;
      var parent = immediateParent;
      final missingParents = <String>[];
      while (parent.isNotEmpty && deckIdForHumanName(parent) == null) {
        checkCancelled();
        missingParents.add(parent);
        final parentSplit = parent.lastIndexOf('::');
        if (parentSplit < 0) break;
        parent = parent.substring(0, parentSplit);
      }
      for (final missingName in missingParents.reversed) {
        _insertRepairDeck(
          Deck(
            name: missingName,
            mtimeSecs: Int64(nowSecs),
            usn: -1,
            common: protoDeck.Deck_Common(
              studyCollapsed: true,
              browserCollapsed: true,
            ),
            kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
          ),
          preserveId: false,
        );
      }
      // Core reports the missing immediate parent per child deck, even when
      // repairing that parent also creates additional ancestors.
      recovered++;
    }
    return recovered;
  }

  void _insertRepairDeck(Deck deck, {required bool preserveId}) {
    final id = preserveId
        ? deck.id
        : _readInt64(
            _database
                .select(
                  'SELECT CASE WHEN ? IN (SELECT id FROM decks) '
                  'THEN (SELECT max(id) + 1 FROM decks) ELSE ? END',
                  [
                    _toSqlInt64(Int64(DateTime.now().millisecondsSinceEpoch)),
                    _toSqlInt64(Int64(DateTime.now().millisecondsSinceEpoch)),
                  ],
                )
                .single
                .columnAt(0),
          );
    var nativeName = normalizeDeckName(deck.name).replaceAll('::', '\x1f');
    while (true) {
      final existingId = _deckStorage.getDeckId(nativeName);
      if (existingId == null || existingId == id) break;
      nativeName = '$nativeName+';
    }
    final kind = switch (deck.kind) {
      NormalDeckKind(:final value) => protoDeck.Deck_KindContainer(
        normal: value,
      ),
      FilteredDeckKind(:final value) => protoDeck.Deck_KindContainer(
        filtered: value,
      ),
    };
    _database.execute(
      '''
INSERT OR REPLACE INTO decks (id, name, mtime_secs, usn, common, kind)
VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        _toSqlInt64(id),
        nativeName,
        _toSqlInt64(deck.mtimeSecs),
        deck.usn,
        deck.common.writeToBuffer(),
        kind.writeToBuffer(),
      ],
    );
  }

  bool _updateNextNewPosition(int nowMillis) {
    final value = _database
        .select('SELECT max(due) + 1 FROM cards WHERE type = 0')
        .single
        .columnAt(0);
    final nextPosition = value == null ? 0 : (value as num).toInt();
    return _setOperationConfig('nextPos', jsonEncode(nextPosition), nowMillis);
  }

  int _fixInvalidIds(int nowMillis, {required void Function() checkCancelled}) {
    final cutoff = nowMillis + 86400000;
    final invalid =
        (_database
                    .select(
                      '''
SELECT (SELECT count(*) FROM notes WHERE id > ?) +
       (SELECT count(*) FROM cards WHERE id > ?) +
       (SELECT count(*) FROM revlog WHERE id > ?)
''',
                      [
                        _toSqlInt64(Int64(cutoff)),
                        _toSqlInt64(Int64(cutoff)),
                        _toSqlInt64(Int64(cutoff)),
                      ],
                    )
                    .single
                    .columnAt(0)
                as num)
            .toInt();
    if (invalid == 0) return 0;
    for (final (source, target, column) in [
      ('notes', 'cards', 'nid'),
      ('cards', 'revlog', 'cid'),
      ('revlog', null, null),
    ]) {
      checkCancelled();
      final invalidCount =
          (_database
                      .select('SELECT count(*) FROM "$source" WHERE id > ?', [
                        cutoff,
                      ])
                      .single
                      .columnAt(0)
                  as num)
              .toInt();
      if (invalidCount == 0) continue;
      final firstNewId = _allocateInvalidIdStart(
        source,
        cutoff: cutoff,
        preferred: nowMillis,
        count: invalidCount,
      );
      _database.execute('DROP TABLE IF EXISTS temp.invalid_ids');
      _database.execute('''
CREATE TEMP TABLE invalid_ids AS
SELECT id, $firstNewId + row_number() OVER (ORDER BY id) - 1 AS new_id
FROM "$source" WHERE id > $cutoff;
''');
      _database.execute(
        'CREATE INDEX temp.invalid_ids_id_idx ON invalid_ids (id)',
      );
      _database.execute('''
UPDATE "$source" SET id = (SELECT new_id FROM invalid_ids WHERE invalid_ids.id = "$source".id)
WHERE id IN (SELECT id FROM invalid_ids);
''');
      if (target case final String targetTable) {
        _database.execute('''
UPDATE "$targetTable" SET "$column" = (SELECT new_id FROM invalid_ids WHERE invalid_ids.id = "$targetTable"."$column")
WHERE "$column" IN (SELECT id FROM invalid_ids)
''');
      }
    }
    _database.execute('DROP TABLE IF EXISTS temp.invalid_ids');
    return invalid;
  }

  int _allocateInvalidIdStart(
    String table, {
    required int cutoff,
    required int preferred,
    required int count,
  }) {
    final maxValidValue = _database
        .select('SELECT max(id) FROM "$table" WHERE id <= ?', [cutoff])
        .single
        .columnAt(0);
    final maxValid = maxValidValue == null
        ? 0
        : _readInt64(maxValidValue).toInt();
    final candidate = preferred > maxValid ? preferred : maxValid + 1;
    if (candidate + count - 1 <= cutoff) return candidate;

    final gapRows = _database.select(
      '''
WITH ordered AS (
  SELECT id, lag(id, 1, 0) OVER (ORDER BY id) AS previous_id
  FROM "$table"
  WHERE id > 0 AND id <= ?
)
SELECT previous_id + 1 AS first_id
FROM ordered
WHERE id - previous_id - 1 >= ?
UNION ALL
SELECT coalesce(max(id), 0) + 1 AS first_id
FROM "$table"
WHERE id > 0 AND id <= ?
HAVING ? - coalesce(max(id), 0) >= ?
ORDER BY first_id
LIMIT 1
''',
      [cutoff, count, cutoff, cutoff, count],
    );
    if (gapRows.isEmpty) {
      throw StateError('no collision-free collection IDs available');
    }
    return _readInt64(gapRows.single['first_id']).toInt();
  }

  Future<int> _fixMissingCardLastReviewTimes({
    required void Function() checkCancelled,
  }) async {
    final entries = _revlogStorage.getAllRevlogEntriesInCardOrder();
    var fixed = 0;
    var index = 0;
    while (index < entries.length) {
      checkCancelled();
      final cardId = entries[index].cardId;
      Int64? lastReviewedAt;
      while (index < entries.length && entries[index].cardId == cardId) {
        checkCancelled();
        final entry = entries[index++];
        if (entry.hasRatingAndAffectsScheduling) {
          lastReviewedAt = entry.id.asSecs();
        } else if (entry.isReset) {
          lastReviewedAt = null;
        }
      }
      if (lastReviewedAt == null) continue;
      final card = await getCard(cardId);
      if (card == null ||
          card.ctype == CardType.newCard ||
          card.lastReviewTimeSecs != null) {
        continue;
      }
      final updated = Card.fromProto(
        card.toProto()..lastReviewTimeSecs = lastReviewedAt,
      );
      _database.execute('UPDATE cards SET data = ? WHERE id = ?', [
        _cardDataJson(updated),
        _toSqlInt64(card.id),
      ]);
      fixed += _database.updatedRows;
    }
    return fixed;
  }
}
