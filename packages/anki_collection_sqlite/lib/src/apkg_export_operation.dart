// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

part of 'collection_sqlite_storage.dart';

extension ApkgExportCollection on CollectionSqliteStorage {
  /// Exports a detached, option-adjusted APKG without modifying this
  /// collection. The returned bytes are produced only after both SQLite
  /// databases and all requested media have been gathered successfully.
  Future<Uint8List> exportApkg({
    ApkgExportLimit? limit,
    ApkgExportOptions options = const ApkgExportOptions(),
  }) async {
    return exportFromSnapshot((copy) async {
      final copyStorage = CollectionSqliteStorage._(
        copy,
        _driver,
        _nowMillis,
        _options,
      );
      var resolvedLimit = limit;
      if (limit?.deckId != null) {
        final decks = copy.select('SELECT id, name FROM decks');
        final target = decks.where(
          (row) => _readInt64(row['id']) == limit!.deckId,
        );
        if (target.isEmpty) {
          throw ArgumentError.value(limit!.deckId, 'deckId', 'unknown deck ID');
        }
        final targetName = target.single['name'] as String;
        final descendants = decks
            .where(
              (row) => (row['name'] as String).startsWith('$targetName\x1f'),
            )
            .map((row) => _readInt64(row['id']));
        resolvedLimit = ApkgExportLimit(
          deckIds: [limit!.deckId!, ...descendants],
        );
      }
      if (resolvedLimit?.deckIds case final requestedDeckIds?) {
        final knownDeckIds = copy
            .select('SELECT id FROM decks')
            .map((row) => _readInt64(row['id']))
            .toSet();
        for (final deckId in requestedDeckIds) {
          if (!knownDeckIds.contains(deckId)) {
            throw ArgumentError.value(deckId, 'deckIds', 'unknown deck ID');
          }
        }
      }

      final noteRows = copy.select('SELECT id FROM notes ORDER BY id');
      final cardRows = copy.select(
        'SELECT id, nid, did FROM cards ORDER BY id',
      );
      final allNotes = noteRows.map((row) => _readInt64(row['id'])).toList();
      final allCards = cardRows
          .map(
            (row) => ApkgCardReference(
              id: _readInt64(row['id']),
              noteId: _readInt64(row['nid']),
              deckId: _readInt64(row['did']),
            ),
          )
          .toList();
      final selection = resolveApkgSelection(
        notes: allNotes,
        cards: allCards,
        limit: resolvedLimit,
      );
      _checkApkgIds(copy, selection, withScheduling: options.withScheduling);
      _pruneApkgCollection(
        copy,
        selection,
        nextPosition:
            copyStorage.readCollectionConfigInt64('nextPos')?.toInt() ?? 1,
        withScheduling: options.withScheduling,
        withDeckConfigs: options.withDeckConfigs,
      );

      final databaseSnapshot = _driver.snapshot;
      if (databaseSnapshot == null) {
        throw const PortableIoUnsupported('database snapshot');
      }
      final collectionBytes = await databaseSnapshot(copy);
      final exportClone = _driver.exportFromSnapshot;
      if (exportClone == null) {
        throw const PortableIoUnsupported('detached database export');
      }
      final compatibilityBytes = await exportClone(copy, (legacyCopy) async {
        await _configureApkgClone(legacyCopy, _options);
        final legacyStorage = CollectionSqliteStorage._(
          legacyCopy,
          _driver,
          _nowMillis,
          _options,
        );
        await downgradeCollectionSchema(
          _ExportMigrationDatabase(legacyCopy),
          CollectionSqliteMigrationCallbacks(
            storage: legacyStorage,
            randomU64: _randomUnsigned64,
          ),
          toVersion: 11,
        );
        return databaseSnapshot(legacyCopy);
      });

      final mediaFiles = options.withMedia
          ? await _gatherApkgMedia(copyStorage, selection)
          : const <String, Uint8List>{};
      return ApkgPackageBuilder.build(
        collectionDatabase: collectionBytes,
        compatibilityDatabase: compatibilityBytes,
        mediaFiles: mediaFiles,
        legacy: options.legacy,
      );
    });
  }
}

Future<void> _configureApkgClone(
  CommonDatabase database,
  CollectionSqliteOptions options,
) async {
  _registerCoreFieldIndexFunction(database);
  registerProcessTextFunction(database);
  registerFnvHashFunction(database);
  registerCardDataFunctions(database);
  registerFsrsVariableFunction(database);
  registerFsrsRetrievabilityFunctions(database);
  registerRegexFunctions(database);
  registerUnicaseCollation(database);
  final configureConnection = options.configureConnection;
  if (configureConnection != null) {
    await Future<void>.sync(() => configureConnection(database));
  }
}

void _pruneApkgCollection(
  CommonDatabase database,
  ApkgSelection selection, {
  required int nextPosition,
  required bool withScheduling,
  required bool withDeckConfigs,
}) {
  final selectedNoteIds = selection.noteIds.toSet();
  final selectedCardIds = selection.cardIds.toSet();
  final selectedNotes = database
      .select('SELECT id, mid, tags FROM notes ORDER BY id')
      .where((row) => selectedNoteIds.contains(_readInt64(row['id'])))
      .toList();
  final selectedCards = database
      .select(
        'SELECT id, nid, did, ord, type, queue, due, ivl, factor, reps, '
        'lapses, `left`, odue, odid, flags, data, '
        'extract_original_position(data) AS original_position '
        'FROM cards ORDER BY id',
      )
      .where((row) => selectedCardIds.contains(_readInt64(row['id'])))
      .toList();

  final decks = database.select('SELECT id, name, common, kind FROM decks');
  final deckIds = <Int64>{};
  for (final row in selectedCards) {
    deckIds.add(_readInt64(row['did']));
    final originalDeckId = _readInt64(row['odid']);
    if (withScheduling && originalDeckId != Int64.ZERO) {
      deckIds.add(originalDeckId);
    }
  }
  // Core omits Default without scheduling so import does not replace the
  // receiver's defaults; cards may still refer to the implicit ID 1 deck.
  if (!withScheduling) deckIds.remove(Int64.ONE);
  final decksByName = <String, Int64>{
    for (final row in decks) row['name'] as String: _readInt64(row['id']),
  };
  final deckNamesById = <Int64, String>{
    for (final row in decks) _readInt64(row['id']): row['name'] as String,
  };
  final pendingDeckIds = [...deckIds];
  while (pendingDeckIds.isNotEmpty) {
    final name = deckNamesById[pendingDeckIds.removeLast()];
    if (name == null) continue;
    var parent = name;
    while (parent.contains('\x1f')) {
      parent = parent.substring(0, parent.lastIndexOf('\x1f'));
      final parentId = decksByName[parent];
      if (parentId != null && deckIds.add(parentId)) {
        pendingDeckIds.add(parentId);
      }
    }
  }

  final validDeckIds = decks.map((row) => _readInt64(row['id'])).toSet();
  final filteredDeckIds = <Int64>{};
  for (final row in decks) {
    final kind = protoDeck.Deck_KindContainer.fromBuffer(
      _apkgBytes(row['kind']),
    );
    if (kind.hasFiltered()) filteredDeckIds.add(_readInt64(row['id']));
  }
  var allowFilteredDecks = true;
  if (withScheduling) {
    for (final row in selectedCards) {
      final originalId = _readInt64(row['odid']);
      final currentId = _readInt64(row['did']);
      final cardIsNormal =
          originalId == Int64.ZERO &&
          validDeckIds.contains(currentId) &&
          !filteredDeckIds.contains(currentId);
      final originalDeckExists =
          originalId == Int64.ONE ||
          (deckIds.contains(originalId) && validDeckIds.contains(originalId));
      if (!cardIsNormal && !originalDeckExists) {
        allowFilteredDecks = false;
        break;
      }
    }
  }

  final deckConfigs = <Int64>{Int64.ONE};
  for (final row in decks) {
    if (!deckIds.contains(_readInt64(row['id']))) continue;
    final kind = protoDeck.Deck_KindContainer.fromBuffer(
      _apkgBytes(row['kind']),
    );
    if (kind.hasNormal()) deckConfigs.add(kind.normal.configId);
  }

  _deleteExceptIds(database, 'cards', 'id', selectedCardIds);
  _deleteExceptIds(database, 'notes', 'id', selectedNoteIds);
  if (withScheduling) {
    _deleteExceptIds(database, 'revlog', 'cid', selectedCardIds);
  } else {
    database.execute('DELETE FROM revlog');
  }
  database.execute('DELETE FROM graves');
  _deleteExceptIds(database, 'decks', 'id', deckIds);
  _deleteExceptIds(
    database,
    'notetypes',
    'id',
    selectedNotes.map((row) => _readInt64(row['mid'])).toSet(),
  );
  _deleteExceptIds(
    database,
    'templates',
    'ntid',
    selectedNotes.map((row) => _readInt64(row['mid'])).toSet(),
  );
  _deleteExceptIds(
    database,
    'fields',
    'ntid',
    selectedNotes.map((row) => _readInt64(row['mid'])).toSet(),
  );
  // Core's minimal APKG collection inserts gathered notes directly without
  // rebuilding the separate tag registry.
  _resetApkgCollectionConfig(database);
  database.execute('DELETE FROM tags');
  // Collection-level preferences belong to the source profile, not the APKG.
  database.execute('DELETE FROM config');
  if (withDeckConfigs) {
    _deleteExceptIds(database, 'deck_config', 'id', deckConfigs);
  } else {
    _deleteExceptIds(database, 'deck_config', 'id', {Int64.ONE});
  }

  if (!withScheduling) {
    for (final row in selectedNotes) {
      final tags = (row['tags'] as String)
          .split(' ')
          .where(
            (tag) =>
                tag.isNotEmpty &&
                tag.toLowerCase() != 'marked' &&
                tag.toLowerCase() != 'leech',
          )
          .join(' ');
      database.execute('UPDATE notes SET tags = ? WHERE id = ?', [
        tags,
        _toSqlInt64(_readInt64(row['id'])),
      ]);
    }
  }

  var position = nextPosition;
  for (final row in selectedCards) {
    final cardId = _readInt64(row['id']);
    final odid = _readInt64(row['odid']);
    if (!withScheduling) {
      final originalDue = _readInt64(row['odue']).toInt();
      final lastPosition = (row['type'] as int) == 0
          ? (odid != Int64.ZERO ? originalDue : _readInt64(row['due']).toInt())
          : row['original_position'] as int?;
      final due = lastPosition ?? position++;
      final resetData = _resetApkgCardData(row['data'] as String);
      database.execute(
        'UPDATE cards SET type=0, queue=0, due=?, ivl=0, factor=0, reps=0, '
        'lapses=0, `left`=0, odue=0, odid=0, flags=0, data=? WHERE id=?',
        [due, resetData, _toSqlInt64(cardId)],
      );
    } else if (!allowFilteredDecks && odid != Int64.ZERO) {
      final currentId = _readInt64(row['did']);
      // Core keeps the current deck for every filtered card in this fallback;
      // that deck is converted to a normal deck below.
      final originalDue = _readInt64(row['odue']).toInt();
      final restoredDue = originalDue != 0
          ? originalDue
          : _readInt64(row['due']).toInt();
      final restoredQueue = switch (row['type'] as int) {
        0 => 0,
        1 || 3 => restoredDue > 1000000000 ? 1 : 3,
        2 => 2,
        _ => throw StateError('invalid card type in APKG export'),
      };
      database.execute(
        'UPDATE cards SET did=?, odid=0, odue=0, due=CASE WHEN ? != 0 '
        'THEN ? ELSE due END, queue=CASE WHEN queue >= 0 THEN ? ELSE queue END '
        'WHERE id=?',
        [
          _toSqlInt64(currentId),
          originalDue,
          originalDue,
          restoredQueue,
          _toSqlInt64(cardId),
        ],
      );
    }
  }

  for (final row in decks) {
    final id = _readInt64(row['id']);
    if (!deckIds.contains(id)) continue;
    final common = protoDeck.Deck_Common.fromBuffer(_apkgBytes(row['common']));
    final kind = protoDeck.Deck_KindContainer.fromBuffer(
      _apkgBytes(row['kind']),
    );
    if (!withScheduling) {
      common.clear();
    }
    if (kind.hasNormal()) {
      if (!withDeckConfigs) kind.normal.configId = Int64.ONE;
      if (!withScheduling) {
        kind.normal.extendNew = 0;
        kind.normal.extendReview = 0;
        kind.normal.clearReviewLimit();
        kind.normal.clearNewLimit();
        kind.normal.clearReviewLimitToday();
        kind.normal.clearNewLimitToday();
      }
    } else if (!allowFilteredDecks || !withScheduling) {
      kind.clearFiltered();
      kind.normal = protoDeck.Deck_Normal(configId: Int64.ONE);
    }
    database.execute('UPDATE decks SET common=?, kind=? WHERE id=?', [
      common.writeToBuffer(),
      kind.writeToBuffer(),
      _toSqlInt64(id),
    ]);
  }
}

void _resetApkgCollectionConfig(CommonDatabase database) {
  final sourceConfig = CollectionSqliteStorage._decodeJsonObjectOrEmpty(
    database.select('SELECT conf FROM col').single['conf'],
  );
  final creationOffsetRows = database.select(
    "SELECT val FROM config WHERE key = 'creationOffset'",
  );
  final storedCreationOffset = creationOffsetRows.isEmpty
      ? sourceConfig['creationOffset']
      : CollectionSqliteStorage._decodeJsonValue(
          creationOffsetRows.single['val'],
        );
  database.execute('UPDATE col SET conf = ?', [
    jsonEncode({
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
      'creationOffset': storedCreationOffset,
      'sched2021': true,
    }),
  ]);
}

String _resetApkgCardData(String value) {
  Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    return '';
  }
  final customData = decoded is Map<String, dynamic>
      ? decoded['cd']
      : decoded is List && decoded.length > 6
      ? decoded[6]
      : null;
  if (customData is! String || customData.isEmpty) return '';
  return jsonEncode({'cd': customData});
}

void _deleteExceptIds(
  CommonDatabase database,
  String table,
  String column,
  Set<Int64> ids,
) {
  if (ids.isEmpty) {
    database.execute('DELETE FROM $table');
    return;
  }
  database.execute(
    'CREATE TEMP TABLE apkg_export_keep_ids (id INTEGER PRIMARY KEY)',
  );
  try {
    for (final chunk in _apkgIdChunks(ids.toList())) {
      final placeholders = List.filled(chunk.length, '(?)').join(',');
      database.execute(
        'INSERT INTO apkg_export_keep_ids (id) VALUES $placeholders',
        chunk.map(_toSqlInt64).toList(),
      );
    }
    database.execute(
      'DELETE FROM $table WHERE $column NOT IN '
      '(SELECT id FROM apkg_export_keep_ids)',
    );
  } finally {
    database.execute('DROP TABLE apkg_export_keep_ids');
  }
}

Iterable<List<T>> _apkgIdChunks<T>(List<T> ids) sync* {
  const chunkSize = 500;
  for (var offset = 0; offset < ids.length; offset += chunkSize) {
    final end = (offset + chunkSize).clamp(0, ids.length);
    yield ids.sublist(offset, end);
  }
}

void _checkApkgIds(
  CommonDatabase database,
  ApkgSelection selection, {
  required bool withScheduling,
}) {
  final nowMillis = BigInt.from(DateTime.now().millisecondsSinceEpoch);
  final tomorrowMillis =
      nowMillis + BigInt.from(const Duration(days: 1).inMilliseconds);
  final ids = <Int64>[...selection.noteIds, ...selection.cardIds];
  if (withScheduling && selection.cardIds.isNotEmpty) {
    for (final chunk in _apkgIdChunks(selection.cardIds)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      ids.addAll(
        database
            .select(
              'SELECT id FROM revlog WHERE cid IN ($placeholders)',
              chunk.map(_toSqlInt64).toList(),
            )
            .map((row) => _readInt64(row['id'])),
      );
    }
  }
  if (ids.any((id) => BigInt.parse(id.toString()) > tomorrowMillis)) {
    throw StateError('invalid APKG entity ID');
  }
}

Future<Map<String, Uint8List>> _gatherApkgMedia(
  CollectionSqliteStorage storage,
  ApkgSelection selection,
) async {
  final references = <String>{};
  final selectedNotetypes = <Int64>{};
  final latexSvgByNotetype = <Int64, bool>{};
  final noteRows = <Row>[];
  for (final chunk in _apkgIdChunks(selection.noteIds)) {
    final placeholders = List.filled(chunk.length, '?').join(',');
    noteRows.addAll(
      storage._database.select(
        'SELECT mid, flds FROM notes WHERE id IN ($placeholders)',
        chunk.map(_toSqlInt64).toList(),
      ),
    );
  }
  for (final row in noteRows) {
    selectedNotetypes.add(_readInt64(row['mid']));
  }
  if (selection.noteIds.isNotEmpty) {
    if (selectedNotetypes.isNotEmpty) {
      for (final chunk in _apkgIdChunks(selectedNotetypes.toList())) {
        final notetypePlaceholders = List.filled(chunk.length, '?').join(',');
        for (final row in storage._database.select(
          'SELECT id, config FROM notetypes WHERE id IN ($notetypePlaceholders)',
          chunk.map(_toSqlInt64).toList(),
        )) {
          final config = protoNotetype.Notetype_Config.fromBuffer(
            _apkgBytes(row['config']),
          );
          final notetypeId = _readInt64(row['id']);
          latexSvgByNotetype[notetypeId] = config.latexSvg;
          _collectCssMediaReferences(config.css, references);
          final templates = storage._database.select(
            'SELECT config FROM templates WHERE ntid = ?',
            [_toSqlInt64(notetypeId)],
          );
          for (final template in templates) {
            final templateConfig =
                protoNotetype.Notetype_Template_Config.fromBuffer(
                  _apkgBytes(template['config']),
                );
            _collectNotetypeMediaReferences(templateConfig.qFormat, references);
            _collectNotetypeMediaReferences(templateConfig.aFormat, references);
          }
        }
      }
    }
  }
  for (final row in noteRows) {
    final notetypeId = _readInt64(row['mid']);
    for (final field in (row['flds'] as String).split('\x1f')) {
      _collectApkgMediaReferences(
        field,
        references,
        latexSvg: latexSvgByNotetype[notetypeId] ?? false,
      );
    }
  }
  final result = <String, Uint8List>{};
  for (final filename in references) {
    try {
      validateAnkiMediaFilename(filename);
      if (!_safeApkgGatherFilename(filename)) continue;
      final stream = await storage.readMedia(filename);
      if (stream == null) continue;
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in stream) {
        bytes.add(chunk);
      }
      result[filename] = bytes.takeBytes();
    } on ArgumentError {
      // Anki skips unsafe media references while gathering an export.
    }
  }
  return result;
}

void _collectApkgMediaReferences(
  String text,
  Set<String> output, {
  bool latexSvg = false,
}) {
  final sound = RegExp(r'\[sound:([^\]]+)\]', caseSensitive: false);
  for (final match in sound.allMatches(text)) {
    final filename = match.group(1);
    if (filename != null && filename.isNotEmpty) {
      output.add(_decodeApkgHtmlEntities(filename));
    }
  }
  final mediaTags = RegExp(
    r'''<\b(?:img|audio|video|object|source)\b(?:[^>]|"[^"]+?"|'[^']+?')+?\b(?:src|data)\b=(?:"([^\"]+?)"[^>]*>|'([^']+?)'[^>]*>|([^ >]+?)(?:\x20[^>]*>|>))''',
    caseSensitive: false,
  );
  for (final match in mediaTags.allMatches(text)) {
    final value = _decodeApkgHtmlEntities(
      match.group(1) ?? match.group(2) ?? match.group(3) ?? '',
    );
    if (value.isNotEmpty) output.add(value);
  }
  final latex = RegExp(
    r'\[latex\](.+?)\[/latex\]|\[\$\](.+?)\[/\$\]|\[\$\$\](.+?)\[/\$\$\]',
    caseSensitive: false,
    dotAll: true,
  );
  for (final match in latex.allMatches(text)) {
    final latex = switch ((match.group(1), match.group(2), match.group(3))) {
      (final String body, _, _) => body,
      (_, final String body, _) => '\$$body\$',
      (_, _, final String body) =>
        r'\begin{displaymath}' + body + r'\end{displaymath}',
      _ => '',
    };
    final normalized = _stripApkgHtml(latex);
    final extension = latexSvg ? 'svg' : 'png';
    output.add('latex-${sha1.convert(utf8.encode(normalized))}.$extension');
  }
}

bool _safeApkgGatherFilename(String filename) {
  // Package names must be safe on every supported host, not only the
  // platform-specific Path implementation used by Core's gather predicate.
  const disallowed = '[]<>:"/?*^\\|';
  return unorm.nfc(filename) == filename &&
      utf8.encode(filename).length <= 120 &&
      !filename.endsWith(' ') &&
      !filename.endsWith('.') &&
      !filename.contains('\u00a0') &&
      !filename.runes.any(
        (rune) => rune < 0x20 || disallowed.contains(String.fromCharCode(rune)),
      ) &&
      !RegExp(
        r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
        caseSensitive: false,
      ).hasMatch(filename);
}

void _collectCssMediaReferences(String css, Set<String> output) {
  final url = RegExp(
    r'''url\(\s*(?:"([^"]+)"|'([^']+)'|([^\s)]+))\s*\)''',
    caseSensitive: false,
  );
  for (final match in url.allMatches(css)) {
    final filename = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
    if (filename.startsWith('_')) output.add(filename);
  }
  final imports = RegExp(
    r'''@import\s+(?:"(_[^" ]+\.css)"|'(_[^' ]+\.css)')''',
    caseSensitive: false,
  );
  for (final match in imports.allMatches(css)) {
    final filename = match.group(1) ?? match.group(2) ?? '';
    if (filename.startsWith('_')) output.add(filename);
  }
}

void _collectNotetypeMediaReferences(String text, Set<String> output) {
  final references = RegExp(
    r'''\[sound:(_[^\]]+)\]|"(_[^" ]+)"|'(_[^' ]+)'|\b(?:src|data)=(_[^ >]+)''',
  );
  for (final match in references.allMatches(text)) {
    final value =
        match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4);
    if (value != null) output.add(value);
  }
}

String _decodeApkgHtmlEntities(String value) =>
    (html_parser.parseFragment(value).text ?? '').replaceAll('\u00a0', ' ');

String _stripApkgHtml(String value) {
  final newlines = value.replaceAll(
    RegExp(r'<br( /)?>|<div>', caseSensitive: false),
    '\n',
  );
  final tags = newlines.replaceAll(
    RegExp(
      r'<!--.*?-->|<style.*?>.*?</style>|<script.*?>.*?</script>|<.*?>',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
  return _decodeApkgHtmlEntities(tags);
}

Uint8List _apkgBytes(Object? value) => switch (value) {
  Uint8List bytes => bytes,
  List<int> bytes => Uint8List.fromList(bytes),
  _ => throw const FormatException('invalid APKG database bytes'),
};

BigInt _randomUnsigned64() {
  final random = Random.secure();
  final high = random.nextInt(1 << 32);
  final low = random.nextInt(1 << 32);
  return (BigInt.from(high) << 32) | BigInt.from(low);
}

final class _ExportMigrationDatabase
    implements CollectionSchemaMigrationDatabase {
  const _ExportMigrationDatabase(this.database);

  final CommonDatabase database;

  @override
  void beginExclusive() => database.execute('BEGIN EXCLUSIVE');

  @override
  void executeBatch(String sql) => database.execute(sql);

  @override
  void commit() => database.execute('COMMIT');

  @override
  void rollback() => database.execute('ROLLBACK');
}
