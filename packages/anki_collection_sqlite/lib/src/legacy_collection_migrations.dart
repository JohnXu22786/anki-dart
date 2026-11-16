// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

part of 'collection_sqlite_storage.dart';

/// Runs Anki Core's non-SQL collection schema transformations on an existing
/// [CollectionSqliteStorage] connection.
///
/// The caller owns the surrounding exclusive transaction. [randomU64] is
/// used only to repair schema-11 note types whose id is zero, and
/// [clock] supplies the modification timestamp used when a migrated deck name
/// changes. Card-ease repairs use the collection USN in server mode and -1 on
/// clients, as in Anki Core.
final class CollectionSqliteMigrationCallbacks
    implements CollectionSchemaMigrationCallbacks {
  const CollectionSqliteMigrationCallbacks({
    required this.storage,
    required this.randomU64,
    this.clock = _migrationNow,
  });

  final CollectionSqliteStorage storage;
  final BigInt Function() randomU64;
  final DateTime Function() clock;

  @override
  Future<void> run(String name, {bool? serverMode}) async {
    switch (name) {
      case 'upgradeDeckConfTo14':
        _upgradeDeckConfigTo14();
      case 'upgradeTagsTo14':
        _upgradeTagsTo14();
      case 'upgradeConfigTo14':
        _upgradeConfigTo14();
      case 'upgradeNotetypesTo15':
        _upgradeNotetypesTo15();
      case 'upgradeDecksTo15':
        _upgradeDecksTo15(serverMode: serverMode);
      case 'upgradeDeckConfTo15':
        _upgradeDeckConfigTo15();
      case 'upgradeDeckConfTo16':
        _upgradeDeckConfigTo16(serverMode: serverMode);
      case 'upgradeTagsTo17':
        await _upgradeTagsTo17();
      case 'downgradeDeckConfFrom16':
        _downgradeDeckConfigFrom16();
      case 'downgradeDecksFrom15':
        _downgradeDecksFrom15();
      case 'downgradeNotetypesFrom15':
        _downgradeNotetypesFrom15();
      case 'downgradeConfigFrom14':
        _downgradeConfigFrom14();
      case 'downgradeTagsFrom14':
        _downgradeTagsFrom14();
      default:
        throw ArgumentError.value(name, 'name', 'unknown collection migration');
    }
  }

  CommonDatabase get _db => storage._database;

  void _upgradeDeckConfigTo14() {
    final source = _colString('dconf');
    final configs = _decodeJsonObject(source);
    for (final entry in configs.entries) {
      final id = _parseLegacyId(entry.key);
      final value = _jsonObject(entry.value, 'deck config ${entry.key}');
      value['id'] = id;
      _db.execute(
        'INSERT INTO deck_config (id, name, mtime_secs, usn, config) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          id,
          _string(value['name']),
          _int(value['mod']),
          _int(value['usn']),
          utf8.encode(jsonEncode(value)),
        ],
      );
    }
    _db.execute("UPDATE col SET dconf = ''");
  }

  void _upgradeTagsTo14() {
    final tags = _decodeJsonObject(_colString('tags'));
    for (final entry in tags.entries) {
      _db.execute('INSERT OR IGNORE INTO tags (tag, usn) VALUES (?, ?)', [
        entry.key,
        _int(entry.value),
      ]);
    }
    _db.execute("UPDATE col SET tags = ''");
  }

  void _upgradeConfigTo14() {
    final config = _decodeJsonObject(_colString('conf'));
    for (final entry in config.entries) {
      _db.execute(
        'INSERT INTO config (key, usn, mtime_secs, val) VALUES (?, 0, 0, ?)',
        [entry.key, utf8.encode(jsonEncode(entry.value))],
      );
    }
    _db.execute("UPDATE col SET conf = ''");
  }

  void _upgradeDeckConfigTo15() {
    final rows = _db.select('SELECT id, config FROM deck_config ORDER BY id');
    for (final row in rows) {
      final id = row.columnAt(0) as int;
      final legacy = _jsonObject(
        jsonDecode(utf8.decode(_bytes(row.columnAt(1)))),
        'deck config $id',
      );
      final config = _deckConfigFromSchema11(legacy);
      // Schema 15 stored the source's starting ease as a percentage.
      config.initialEase *= 100;
      _db.execute('UPDATE deck_config SET config = ? WHERE id = ?', [
        config.writeToBuffer(),
        id,
      ]);
    }
  }

  void _upgradeDeckConfigTo16({required bool? serverMode}) {
    final invalid = <int>[];
    final rows = _db.select('SELECT id, config FROM deck_config ORDER BY id');
    for (final row in rows) {
      final id = row.columnAt(0) as int;
      final config = protoConfig.DeckConfig_Config.fromBuffer(
        _bytes(row.columnAt(1)),
      );
      config.initialEase /= 100;
      if (config.initialEase <= 1.3) {
        config.initialEase = 2.5;
        invalid.add(id);
      }
      _db.execute('UPDATE deck_config SET config = ? WHERE id = ?', [
        config.writeToBuffer(),
        id,
      ]);
    }
    if (invalid.isEmpty) return;

    final currentUsn = serverMode == true ? _colInt('usn') : -1;
    final invalidIds = invalid.toSet();
    final affectedDeckIds = storage.decks
        .getAllDecks()
        .where(
          (deck) => switch (deck.kind) {
            NormalDeckKind(:final value) => invalidIds.contains(
              value.configId.toInt(),
            ),
            FilteredDeckKind() => false,
          },
        )
        .map((deck) => deck.id.toInt())
        .toSet()
        .toList(growable: false);
    if (affectedDeckIds.isEmpty) return;
    final placeholders = List.filled(affectedDeckIds.length, '?').join(', ');
    final cards = _db.select(
      'SELECT id, did, odid FROM cards WHERE factor != 0 AND factor <= 2000 '
      'AND (did IN ($placeholders) OR odid IN ($placeholders))',
      [...affectedDeckIds, ...affectedDeckIds],
    );
    for (final card in cards) {
      _db.execute('UPDATE cards SET factor = 2500, usn = ? WHERE id = ?', [
        currentUsn,
        card.columnAt(0),
      ]);
    }
  }

  void _upgradeDecksTo15({required bool? serverMode}) {
    if (serverMode == null) {
      throw ArgumentError.notNull('serverMode');
    }
    final legacyDecks = _decodeJsonObject(_colString('decks'));
    final usedNames = <String>{};
    final usn = serverMode ? _colInt('usn') : -1;
    final mod = clock().millisecondsSinceEpoch ~/ 1000;
    for (final entry in legacyDecks.entries) {
      final oldName = _string(
        _jsonObject(entry.value, 'deck ${entry.key}')['name'],
      );
      final original = _jsonObject(entry.value, 'deck ${entry.key}');
      final deck = Deck.fromProto(_legacyDeckProto(original));
      var newName = deck.name;
      var changed = newName != oldName;
      while (!usedNames.add(unicodeCaseFold(newName))) {
        newName = '${newName}_';
        changed = true;
      }
      final migrated = changed
          ? Deck(
              id: deck.id,
              name: newName,
              mtimeSecs: Int64(mod),
              usn: usn,
              common: deck.common,
              kind: deck.kind,
            )
          : deck;
      storage.decks.addOrUpdateDeckWithExistingId(migrated);
    }
    _db.execute("UPDATE col SET decks = ''");
  }

  protoDeck.Deck _legacyDeckProto(Map<String, Object?> source) {
    final id = _int64(source['id']);
    final name = _string(source['name']);
    final usn = _int(source['usn']);
    final mod = _int(source['mod'] ?? 0);
    final today = <String, List<int>>{
      'lrnToday': _pair(source['lrnToday']),
      'revToday': _pair(source['revToday']),
      'newToday': _pair(source['newToday']),
      'timeToday': _pair(source['timeToday']),
    };
    final day = [
      today['timeToday']!,
      today['newToday']!,
      today['revToday']!,
    ].map((value) => value[0]).fold<int>(0, (a, b) => a > b ? a : b);
    final common = protoDeck.Deck_Common(
      studyCollapsed: _bool(source['collapsed'], false),
      browserCollapsed: _bool(source['browserCollapsed'], false),
      lastDayStudied: day & 0xffffffff,
      learningStudied: today['lrnToday']![0] == day ? today['lrnToday']![1] : 0,
      reviewStudied: today['revToday']![0] == day ? today['revToday']![1] : 0,
      newStudied: today['newToday']![0] == day ? today['newToday']![1] : 0,
      millisecondsStudied: today['timeToday']![1],
      other: utf8.encode(
        jsonEncode(
          _withoutKeys(source, {
            ..._deckReservedKeys,
            'md',
            'resched',
            'terms',
            'separate',
            'delays',
            'previewDelay',
            'previewAgainSecs',
            'previewHardSecs',
            'previewGoodSecs',
          }),
        ),
      ),
    );
    final isFiltered = source['dyn'] == true || _int(source['dyn']) == 1;
    if (!isFiltered) {
      final configId = _int64(source['conf'] ?? 1);
      return protoDeck.Deck(
        id: id,
        name: name,
        mtimeSecs: Int64(mod),
        usn: usn,
        common: common,
        normal: protoDeck.Deck_Normal(
          configId: configId,
          extendNew: _num(source['extendNew'], 0).clamp(0, 0x7fffffff),
          extendReview: _num(source['extendRev'], 0).clamp(0, 0x7fffffff),
          description: _string(source['desc'] ?? ''),
          markdownDescription: _bool(source['md'], false),
          reviewLimit: _optionalInt(source['reviewLimit']),
          newLimit: _optionalInt(source['newLimit']),
          reviewLimitToday: _dayLimit(source['reviewLimitToday']),
          newLimitToday: _dayLimit(source['newLimitToday']),
          desiredRetention: source['desiredRetention'] == null
              ? null
              : _numDouble(source['desiredRetention'], 0) / 100,
        ),
      );
    }
    final terms = source['terms'];
    return protoDeck.Deck(
      id: id,
      name: name,
      mtimeSecs: Int64(mod),
      usn: usn,
      common: common,
      filtered: protoDeck.Deck_Filtered(
        reschedule: _bool(source['resched'], false),
        searchTerms: terms is List
            ? terms.map(_legacySearchTerm).toList(growable: false)
            : const [],
        delays: _numbers(source['delays']),
        previewDelay: _num(source['previewDelay'], 0),
        previewAgainSecs: _num(source['previewAgainSecs'], 0),
        previewHardSecs: _num(source['previewHardSecs'], 0),
        previewGoodSecs: _num(source['previewGoodSecs'], 0),
      ),
    );
  }

  protoDeck.Deck_Filtered_SearchTerm _legacySearchTerm(Object? value) {
    if (value is! List || value.length < 3) {
      throw const FormatException('invalid filtered deck term');
    }
    return protoDeck.Deck_Filtered_SearchTerm(
      search: _string(value[0]),
      limit: _num(value[1], 0).clamp(0, 0x7fffffff),
      order:
          protoDeck.Deck_Filtered_SearchTerm_Order.valueOf(_num(value[2], 0)) ??
          protoDeck.Deck_Filtered_SearchTerm_Order.OLDEST_REVIEWED_FIRST,
    );
  }

  protoDeck.Deck_Normal_DayLimit? _dayLimit(Object? value) {
    if (value == null) return null;
    if (value is! Map) throw const FormatException('invalid deck day limit');
    final map = _jsonObject(value, 'deck day limit');
    return protoDeck.Deck_Normal_DayLimit(
      limit: _num(map['limit'], 0),
      today: _num(map['today'], 0),
    );
  }

  void _downgradeDecksFrom15() {
    final decks = <String, Object?>{};
    for (final deck in storage.decks.getAllDecks()) {
      decks[deck.id.toString()] = _deckToSchema11(deck);
    }
    _db.execute('UPDATE col SET decks = ?', [jsonEncode(decks)]);
  }

  void _upgradeNotetypesTo15() {
    final source = _decodeJsonObject(_colString('models'));
    final usedNames = <String>{};
    for (final entry in source.entries) {
      final legacy = _jsonObject(entry.value, 'notetype ${entry.key}');
      var id = _parseLegacyId(entry.key);
      if (id == 0) {
        id = (randomU64().toUnsigned(32).toInt()).clamp(1, 0xffffffff);
      }
      final notetype = Notetype.fromProto(_legacyNotetypeProto(legacy, id));
      notetype.normalizeNames();
      notetype.ensureNamesUnique();
      while (!usedNames.add(unicodeCaseFold(notetype.name))) {
        notetype.name = '${notetype.name}_';
      }
      _writeNotetype(notetype);
    }
    _db.execute("UPDATE col SET models = ''");
  }

  protoNotetype.Notetype _legacyNotetypeProto(
    Map<String, Object?> source,
    int id,
  ) {
    final fields = source['flds'];
    final templates = source['tmpls'];
    final requirements = source['req'];
    final sourceType = _num(source['type'], 0);
    final other = _withoutKeys(source, _notetypeReservedKeys);
    final config = protoNotetype.Notetype_Config(
      kind: sourceType == 1
          ? protoNotetype.Notetype_Config_Kind.KIND_CLOZE
          : protoNotetype.Notetype_Config_Kind.KIND_NORMAL,
      sortFieldIdx: _num(source['sortf'], 0),
      css: _string(source['css'] ?? ''),
      targetDeckIdUnused: Int64(_num(source['did'], 0)),
      latexPre: _string(source['latexPre'] ?? ''),
      latexPost: _string(source['latexPost'] ?? ''),
      latexSvg: _bool(source['latexsvg'], false),
      reqs: requirements is List
          ? requirements.map(_legacyRequirement).toList(growable: false)
          : const [],
      originalStockKind:
          protoNotetype.StockNotetype_OriginalStockKind.valueOf(
            _num(source['originalStockKind'], 0),
          ) ??
          protoNotetype
              .StockNotetype_OriginalStockKind
              .ORIGINAL_STOCK_KIND_UNKNOWN,
      originalId: source['originalId'] == null
          ? null
          : Int64(_int(source['originalId'])),
      other: utf8.encode(jsonEncode(other)),
    );
    final noteFields = fields is List
        ? fields.map(_legacyNoteField).toList(growable: false)
        : <NoteField>[];
    final cardTemplates = templates is List
        ? templates.map(_legacyTemplate).toList(growable: false)
        : <CardTemplate>[];
    return protoNotetype.Notetype(
      id: Int64(id),
      name: _string(source['name'] ?? ''),
      mtimeSecs: Int64(_num(source['mod'], 0)),
      usn: _num(source['usn'], 0),
      fields: noteFields.map((field) => field.toProto()).toList(),
      templates: cardTemplates.map((template) => template.toProto()).toList(),
      config: config,
    );
  }

  NoteField _legacyNoteField(Object? value) {
    final field = _jsonObject(value, 'notetype field');
    final other = _withoutKeys(field, _fieldReservedKeys);
    final config = protoNotetype.Notetype_Field_Config(
      sticky: _bool(field['sticky'], false),
      rtl: _bool(field['rtl'], false),
      fontName: _string(field['font'] ?? 'Arial'),
      fontSize: _num(field['size'], 20),
      description: _string(field['description'] ?? ''),
      plainText: _bool(field['plainText'], false),
      collapsed: _bool(field['collapsed'], false),
      excludeFromSearch: _bool(field['excludeFromSearch'], false),
      id: field['id'] == null ? null : Int64(_int(field['id'])),
      tag: field['tag'] == null ? null : _num(field['tag'], 0),
      preventDeletion: _bool(field['preventDeletion'], false),
      other: utf8.encode(jsonEncode(other)),
    );
    final ord = field['ord'] == null ? null : _num(field['ord'], 0);
    return NoteField(
      ord: ord,
      name: _string(field['name'] ?? ''),
      config: config,
    );
  }

  CardTemplate _legacyTemplate(Object? value) {
    final template = _jsonObject(value, 'notetype template');
    final other = _withoutKeys(template, _templateReservedKeys);
    final config = protoNotetype.Notetype_Template_Config(
      qFormat: _string(template['qfmt'] ?? ''),
      aFormat: _string(template['afmt'] ?? ''),
      qFormatBrowser: _string(template['bqfmt'] ?? ''),
      aFormatBrowser: _string(template['bafmt'] ?? ''),
      targetDeckId: Int64(_num(template['did'], 0)),
      browserFontName: _string(template['bfont'] ?? ''),
      browserFontSize: _num(template['bsize'], 0),
      id: template['id'] == null ? null : Int64(_int(template['id'])),
      other: utf8.encode(jsonEncode(other)),
    );
    return CardTemplate(
      ord: template['ord'] == null ? null : _num(template['ord'], 0),
      name: _string(template['name'] ?? ''),
      config: config,
    );
  }

  protoNotetype.Notetype_Config_CardRequirement _legacyRequirement(
    Object? value,
  ) {
    if (value is! List || value.length < 3) {
      throw const FormatException('invalid note type card requirement');
    }
    final kind = switch (_string(value[1])) {
      'any' => protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_ANY,
      'all' => protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_ALL,
      _ => protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_NONE,
    };
    final fieldOrds = value[2] is List
        ? (value[2] as List).map((item) => _num(item, 0))
        : const <int>[];
    return protoNotetype.Notetype_Config_CardRequirement(
      cardOrd: _num(value[0], 0),
      kind: kind,
      fieldOrds: fieldOrds,
    );
  }

  void _writeNotetype(Notetype notetype) {
    final id = notetype.id.value.toInt();
    _db.execute(
      'INSERT OR REPLACE INTO notetypes (id, name, mtime_secs, usn, config) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        id,
        notetype.name,
        notetype.mtimeSecs.toInt(),
        notetype.usn,
        notetype.config.writeToBuffer(),
      ],
    );
    _db.execute('DELETE FROM fields WHERE ntid = ?', [id]);
    for (var index = 0; index < notetype.fields.length; index++) {
      final field = notetype.fields[index];
      _db.execute(
        'INSERT INTO fields (ntid, ord, name, config) VALUES (?, ?, ?, ?)',
        [id, index, field.name, field.config.writeToBuffer()],
      );
    }
    _db.execute('DELETE FROM templates WHERE ntid = ?', [id]);
    for (var index = 0; index < notetype.templates.length; index++) {
      final template = notetype.templates[index];
      _db.execute(
        'INSERT INTO templates (ntid, ord, name, mtime_secs, usn, config) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          id,
          index,
          template.name,
          template.mtimeSecs.toInt(),
          template.usn,
          template.config.writeToBuffer(),
        ],
      );
    }
  }

  void _downgradeNotetypesFrom15() {
    final notetypes = <String, Object?>{};
    for (final row in _db.select(
      'SELECT id, name, mtime_secs, usn, config FROM notetypes ORDER BY name',
    )) {
      final id = row.columnAt(0) as int;
      final fields = <Object?>[];
      for (final field in _db.select(
        'SELECT ord, name, config FROM fields WHERE ntid = ? ORDER BY ord',
        [id],
      )) {
        fields.add(
          _fieldToSchema11(
            field.columnAt(1) as String,
            protoNotetype.Notetype_Field_Config.fromBuffer(
              _bytes(field.columnAt(2)),
            ),
            field.columnAt(0) as int,
          ),
        );
      }
      final templates = <Object?>[];
      for (final template in _db.select(
        'SELECT ord, name, config FROM templates WHERE ntid = ? ORDER BY ord',
        [id],
      )) {
        templates.add(
          _templateToSchema11(
            template.columnAt(1) as String,
            protoNotetype.Notetype_Template_Config.fromBuffer(
              _bytes(template.columnAt(2)),
            ),
            template.columnAt(0) as int,
          ),
        );
      }
      final config = protoNotetype.Notetype_Config.fromBuffer(
        _bytes(row.columnAt(4)),
      );
      notetypes['$id'] = _notetypeToSchema11(
        config,
        id: id,
        name: row.columnAt(1) as String,
        mod: row.columnAt(2) as int,
        usn: row.columnAt(3) as int,
        fields: fields,
        templates: templates,
      );
    }
    _db.execute('UPDATE col SET models = ?', [jsonEncode(notetypes)]);
  }

  Map<String, Object?> _fieldToSchema11(
    String name,
    protoNotetype.Notetype_Field_Config config,
    int ord,
  ) {
    final other = _decodeOther(config.other, 'field other')
      ..removeWhere((key, _) => _fieldReservedKeys.contains(key));
    return {
      ...other,
      'name': name,
      'ord': ord,
      'sticky': config.sticky,
      'rtl': config.rtl,
      'font': config.fontName,
      'size': config.fontSize,
      'description': config.description,
      'plainText': config.plainText,
      'collapsed': config.collapsed,
      'excludeFromSearch': config.excludeFromSearch,
      'id': config.hasId() ? config.id.toInt() : null,
      'tag': config.hasTag() ? config.tag : null,
      'preventDeletion': config.preventDeletion,
    };
  }

  Map<String, Object?> _templateToSchema11(
    String name,
    protoNotetype.Notetype_Template_Config config,
    int ord,
  ) {
    final other = _decodeOther(config.other, 'template other')
      ..removeWhere((key, _) => _templateReservedKeys.contains(key));
    return {
      ...other,
      'name': name,
      'ord': ord,
      'qfmt': config.qFormat,
      'afmt': config.aFormat,
      'bqfmt': config.qFormatBrowser,
      'bafmt': config.aFormatBrowser,
      'did': config.targetDeckId == Int64.ZERO
          ? null
          : config.targetDeckId.toInt(),
      'bfont': config.browserFontName,
      'bsize': config.browserFontSize,
      'id': config.hasId() ? config.id.toInt() : null,
    };
  }

  Map<String, Object?> _notetypeToSchema11(
    protoNotetype.Notetype_Config config, {
    required int id,
    required String name,
    required int mod,
    required int usn,
    required List<Object?> fields,
    required List<Object?> templates,
  }) {
    final other = _decodeOther(config.other, 'notetype other')
      ..removeWhere((key, _) => _notetypeReservedKeys.contains(key));
    final requirements = [
      for (final requirement in config.reqs)
        [
          requirement.cardOrd,
          switch (requirement.kind) {
            protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_ANY =>
              'any',
            protoNotetype.Notetype_Config_CardRequirement_Kind.KIND_ALL =>
              'all',
            _ => 'none',
          },
          requirement.fieldOrds,
        ],
    ];
    return {
      ...other,
      'id': id,
      'name': name,
      'type': config.kind.value,
      'mod': mod,
      'usn': usn,
      'sortf': config.sortFieldIdx,
      'did': config.targetDeckIdUnused == Int64.ZERO
          ? null
          : config.targetDeckIdUnused.toInt(),
      'tmpls': templates,
      'flds': fields,
      'css': config.css,
      'latexPre': config.latexPre,
      'latexPost': config.latexPost,
      'latexsvg': config.latexSvg,
      'req': requirements,
      if (config.originalStockKind.value != 0)
        'originalStockKind': config.originalStockKind.value,
      if (config.hasOriginalId()) 'originalId': config.originalId.toInt(),
    };
  }

  Map<String, Object?> _decodeOther(List<int> bytes, String label) {
    if (bytes.isEmpty) return {};
    try {
      return _jsonObject(jsonDecode(utf8.decode(bytes)), label);
    } on Object {
      // Core's schema-11 serializers drop malformed `other` bytes.
      return {};
    }
  }

  Map<String, Object?> _mapOrEmpty(Object? value) =>
      value is Map ? _jsonObject(value, 'other fields') : <String, Object?>{};

  Map<String, Object?> _deckToSchema11(Deck deck) {
    final commonOther = _decodeOther(deck.common.other, 'deck common other');
    commonOther.removeWhere((key, _) => _deckReservedKeys.contains(key));
    final today = _signed32(deck.common.lastDayStudied);
    final result = <String, Object?>{
      ...commonOther,
      'id': deck.id.toInt(),
      'mod': deck.mtimeSecs.toInt(),
      'name': deck.name,
      'usn': deck.usn,
      'lrnToday': [today, deck.common.learningStudied],
      'revToday': [today, deck.common.reviewStudied],
      'newToday': [today, deck.common.newStudied],
      'timeToday': [today, deck.common.millisecondsStudied],
      'collapsed': deck.common.studyCollapsed,
      'browserCollapsed': deck.common.browserCollapsed,
      'dyn': deck.kind is FilteredDeckKind ? 1 : 0,
    };
    switch (deck.kind) {
      case NormalDeckKind(:final value):
        result.addAll({
          'conf': value.configId.toInt(),
          'extendNew': value.extendNew,
          'extendRev': value.extendReview,
          'desc': value.description,
          if (value.markdownDescription) 'md': true,
          if (value.hasReviewLimit()) 'reviewLimit': value.reviewLimit,
          if (value.hasNewLimit()) 'newLimit': value.newLimit,
          if (value.hasReviewLimitToday())
            'reviewLimitToday': {
              'limit': value.reviewLimitToday.limit,
              'today': value.reviewLimitToday.today,
            },
          if (value.hasNewLimitToday())
            'newLimitToday': {
              'limit': value.newLimitToday.limit,
              'today': value.newLimitToday.today,
            },
          if (value.hasDesiredRetention())
            'desiredRetention': (value.desiredRetention * 100).toInt(),
        });
      case FilteredDeckKind(:final value):
        result.addAll({
          'resched': value.reschedule,
          'terms': [
            for (final term in value.searchTerms)
              [term.search, term.limit, term.order.value],
          ],
          'separate': true,
          if (value.delays.isNotEmpty) 'delays': value.delays,
          'previewDelay': value.previewDelay,
          'previewAgainSecs': value.previewAgainSecs,
          'previewHardSecs': value.previewHardSecs,
          'previewGoodSecs': value.previewGoodSecs,
        });
    }
    return result;
  }

  protoConfig.DeckConfig_Config _deckConfigFromSchema11(
    Map<String, Object?> legacy,
  ) {
    final newValues = _deckConfigBlock(legacy['new'], const {
      'bury': false,
      'delays': [1, 10],
      'initialFactor': 2500,
      'ints': [1, 4, 0],
      'order': 1,
      'perDay': 20,
    });
    final reviewValues = _deckConfigBlock(legacy['rev'], const {
      'bury': false,
      'ease4': 1.3,
      'ivlFct': 1.0,
      'maxIvl': 36500,
      'perDay': 200,
      'hardFactor': 1.2,
    });
    final lapseValues = _deckConfigBlock(legacy['lapse'], const {
      'delays': [10],
      'leechAction': 1,
      'leechFails': 8,
      'minInt': 1,
      'mult': 0.0,
    });
    final other = _deckConfigOther(
      legacy,
      newValues,
      reviewValues,
      lapseValues,
    );
    final questionAction = _strictEnumValue(
      legacy['questionAction'] ?? 0,
      maximum: 1,
      label: 'questionAction',
    );
    final answerAction = _strictEnumValue(
      legacy['answerAction'] ?? 0,
      maximum: 4,
      label: 'answerAction',
    );
    final intervals = legacy['new'] is Map ? newValues['ints'] : null;
    final ints = intervals is List ? intervals : const [1, 4];
    final initialFactor = _num(newValues['initialFactor'], 2500);
    final c = protoConfig.DeckConfig_Config(
      learnSteps: _numbers(newValues['delays'], const [1, 10]),
      relearnSteps: _numbers(lapseValues['delays'], const [10]),
      fsrsParams4: _numbers(legacy['fsrsParams'] ?? legacy['fsrsWeights']),
      fsrsParams5: _numbers(legacy['fsrsParams5']),
      fsrsParams6: _numbers(legacy['fsrsParams6']),
      easyDaysPercentages: _numbers(legacy['easyDaysPercentages'], const [
        1,
        1,
        1,
        1,
        1,
        1,
        1,
      ]),
      newPerDay: _num(newValues['perDay'], 20),
      reviewsPerDay: _num(reviewValues['perDay'], 200),
      initialEase: initialFactor / 1000,
      easyMultiplier: _numDouble(reviewValues['ease4'], 1.3),
      hardMultiplier: _numDouble(reviewValues['hardFactor'], 1.2),
      lapseMultiplier: _numDouble(lapseValues['mult'], 0),
      intervalMultiplier: _numDouble(reviewValues['ivlFct'], 1),
      maximumReviewInterval: _num(reviewValues['maxIvl'], 36500),
      minimumLapseInterval: _num(lapseValues['minInt'], 1),
      graduatingIntervalGood: _num(ints.isNotEmpty ? ints[0] : null, 1),
      graduatingIntervalEasy: _num(ints.length > 1 ? ints[1] : null, 4),
      newCardInsertOrder:
          protoConfig.DeckConfig_Config_NewCardInsertOrder.valueOf(
            _num(newValues['order'], 1) == 0 ? 1 : 0,
          ),
      newCardGatherPriority:
          protoConfig.DeckConfig_Config_NewCardGatherPriority.valueOf(
            _num(legacy['newGatherPriority'], 0),
          ),
      newCardSortOrder: protoConfig.DeckConfig_Config_NewCardSortOrder.valueOf(
        _num(legacy['newSortOrder'], 0),
      ),
      reviewOrder: protoConfig.DeckConfig_Config_ReviewCardOrder.valueOf(
        _num(legacy['reviewOrder'], 0),
      ),
      newMix: protoConfig.DeckConfig_Config_ReviewMix.valueOf(
        _num(legacy['newMix'], 0),
      ),
      interdayLearningMix: protoConfig.DeckConfig_Config_ReviewMix.valueOf(
        _num(legacy['interdayLearningMix'], 0),
      ),
      leechAction:
          protoConfig.DeckConfig_Config_LeechAction.valueOf(
            _num(lapseValues['leechAction'], 1),
          ) ??
          protoConfig.DeckConfig_Config_LeechAction.LEECH_ACTION_TAG_ONLY,
      leechThreshold: _num(lapseValues['leechFails'], 8),
      disableAutoplay: !(_bool(legacy['autoplay'], true)),
      capAnswerTimeToSecs: _num(legacy['maxTaken'], 60).clamp(0, 0x7fffffff),
      showTimer: _num(legacy['timer'], 0) != 0,
      stopTimerOnAnswer: _bool(legacy['stopTimerOnAnswer'], false),
      secondsToShowQuestion: _numDouble(legacy['secondsToShowQuestion'], 0),
      secondsToShowAnswer: _numDouble(legacy['secondsToShowAnswer'], 0),
      questionAction: protoConfig.DeckConfig_Config_QuestionAction.valueOf(
        questionAction,
      ),
      answerAction: protoConfig.DeckConfig_Config_AnswerAction.valueOf(
        answerAction,
      ),
      waitForAudio: _bool(legacy['waitForAudio'], true),
      skipQuestionWhenReplayingAnswer: !_bool(legacy['replayq'], true),
      buryNew: _bool(newValues['bury'], false),
      buryReviews: _bool(reviewValues['bury'], false),
      buryInterdayLearning: _bool(legacy['buryInterdayLearning'], false),
      newPerDayMinimum: _num(legacy['newPerDayMinimum'], 0),
      desiredRetention: _numDouble(legacy['desiredRetention'], .9),
      historicalRetention: _numDouble(legacy['sm2Retention'], .9),
      paramSearch: _string(legacy['weightSearch'] ?? ''),
      ignoreRevlogsBeforeDate: _string(legacy['ignoreRevlogsBeforeDate'] ?? ''),
      other: utf8.encode(jsonEncode(other)),
    );
    return c;
  }

  Map<String, Object?> _deckConfigBlock(
    Object? value,
    Map<String, Object?> defaults,
  ) => value is Map ? _jsonObject(value, 'deck config block') : {...defaults};

  Map<String, Object?> _deckConfigOther(
    Map<String, Object?> top,
    Map<String, Object?> newValues,
    Map<String, Object?> reviewValues,
    Map<String, Object?> lapseValues,
  ) {
    final topOther = _withoutKeys(top, _deckConfigReservedKeys);
    final newOther = _withoutKeys(newValues, const {
      'order',
      'delays',
      'bury',
      'perDay',
      'initialFactor',
      'ints',
    });
    final reviewOther = _withoutKeys(reviewValues, const {
      'maxIvl',
      'hardFactor',
      'ease4',
      'ivlFct',
      'perDay',
      'bury',
    });
    final lapseOther = _withoutKeys(lapseValues, const {
      'leechFails',
      'mult',
      'leechAction',
      'delays',
      'minInt',
    });
    if (newOther.isNotEmpty) topOther['new'] = newOther;
    if (reviewOther.isNotEmpty) topOther['rev'] = reviewOther;
    if (lapseOther.isNotEmpty) topOther['lapse'] = lapseOther;
    return topOther;
  }

  void _downgradeDeckConfigFrom16() {
    final configs = <String, Object?>{};
    for (final row in _db.select(
      'SELECT id, name, mtime_secs, usn, config FROM deck_config ORDER BY id',
    )) {
      final id = row.columnAt(0) as int;
      final conf = protoConfig.DeckConfig_Config.fromBuffer(
        _bytes(row.columnAt(4)),
      );
      configs['$id'] = _deckConfigToSchema11(
        conf,
        id: id,
        name: row.columnAt(1) as String,
        mod: row.columnAt(2) as int,
        usn: row.columnAt(3) as int,
      );
    }
    _db.execute('UPDATE col SET dconf = ?', [jsonEncode(configs)]);
  }

  Map<String, Object?> _deckConfigToSchema11(
    protoConfig.DeckConfig_Config conf, {
    required int id,
    required String name,
    required int mod,
    required int usn,
  }) {
    final extra = _decodeOther(conf.other, 'deck config other');
    final newOther = _mapOrEmpty(extra.remove('new'));
    final revOther = _mapOrEmpty(extra.remove('rev'));
    final lapseOther = _mapOrEmpty(extra.remove('lapse'));
    extra.removeWhere((key, _) => _deckConfigReservedKeys.contains(key));
    newOther.removeWhere(
      (key, _) => const {
        'order',
        'delays',
        'bury',
        'perDay',
        'initialFactor',
        'ints',
      }.contains(key),
    );
    revOther.removeWhere(
      (key, _) => const {
        'maxIvl',
        'hardFactor',
        'ease4',
        'ivlFct',
        'perDay',
        'bury',
      }.contains(key),
    );
    lapseOther.removeWhere(
      (key, _) => const {
        'leechFails',
        'mult',
        'leechAction',
        'delays',
        'minInt',
      }.contains(key),
    );
    if (newOther.isNotEmpty) extra['new'] = newOther;
    if (revOther.isNotEmpty) extra['rev'] = revOther;
    if (lapseOther.isNotEmpty) extra['lapse'] = lapseOther;
    return {
      ...extra,
      'id': id,
      'mod': mod,
      'name': name,
      'usn': usn,
      'maxTaken': conf.capAnswerTimeToSecs,
      'autoplay': !conf.disableAutoplay,
      'timer': conf.showTimer ? 1 : 0,
      'replayq': !conf.skipQuestionWhenReplayingAnswer,
      'new': {
        ...newOther,
        'bury': conf.buryNew,
        'delays': conf.learnSteps,
        'initialFactor': (conf.initialEase * 1000).toInt(),
        'ints': [conf.graduatingIntervalGood, conf.graduatingIntervalEasy, 0],
        'order': conf.newCardInsertOrder.value == 1 ? 0 : 1,
        'perDay': conf.newPerDay,
      },
      'rev': {
        ...revOther,
        'bury': conf.buryReviews,
        'ease4': conf.easyMultiplier,
        'ivlFct': conf.intervalMultiplier,
        'maxIvl': conf.maximumReviewInterval,
        'perDay': conf.reviewsPerDay,
        'hardFactor': conf.hardMultiplier,
      },
      'lapse': {
        ...lapseOther,
        'delays': conf.relearnSteps,
        'leechAction': conf.leechAction.value,
        'leechFails': conf.leechThreshold,
        'minInt': conf.minimumLapseInterval,
        'mult': conf.lapseMultiplier,
      },
      'dyn': false,
      'newMix': conf.newMix.value,
      'newPerDayMinimum': conf.newPerDayMinimum,
      'interdayLearningMix': conf.interdayLearningMix.value,
      'reviewOrder': conf.reviewOrder.value,
      'newSortOrder': conf.newCardSortOrder.value,
      'newGatherPriority': conf.newCardGatherPriority.value,
      'buryInterdayLearning': conf.buryInterdayLearning,
      'fsrsWeights': conf.fsrsParams4,
      'fsrsParams5': conf.fsrsParams5,
      'fsrsParams6': conf.fsrsParams6,
      'desiredRetention': conf.desiredRetention,
      'ignoreRevlogsBeforeDate': conf.ignoreRevlogsBeforeDate,
      'easyDaysPercentages': conf.easyDaysPercentages,
      'stopTimerOnAnswer': conf.stopTimerOnAnswer,
      'secondsToShowQuestion': conf.secondsToShowQuestion,
      'secondsToShowAnswer': conf.secondsToShowAnswer,
      'questionAction': conf.questionAction.value,
      'answerAction': conf.answerAction.value,
      'waitForAudio': conf.waitForAudio,
      'sm2Retention': conf.historicalRetention,
      'weightSearch': conf.paramSearch,
    };
  }

  Future<void> _upgradeTagsTo17() async {
    final rows = _db.select('SELECT tag, usn FROM tags ORDER BY tag');
    final tags = [
      for (final row in rows)
        (row.columnAt(0) as String, row.columnAt(1) as int),
    ];
    await storage.executeBatch(collectionSchemaSchema17UpgradeSql);
    for (final (tag, usn) in tags) {
      _db.execute(
        'INSERT INTO tags (tag, usn, collapsed, config) VALUES (?, ?, 1, NULL)',
        [tag, usn],
      );
    }
  }

  void _downgradeConfigFrom14() {
    final values = <String, Object?>{};
    for (final row in _db.select('SELECT key, val FROM config ORDER BY key')) {
      values[row.columnAt(0) as String] = jsonDecode(
        utf8.decode(_bytes(row.columnAt(1))),
      );
    }
    _db.execute('UPDATE col SET conf = ?', [jsonEncode(values)]);
  }

  void _downgradeTagsFrom14() {
    final tags = <String, int>{};
    for (final row in _db.select('SELECT tag, usn FROM tags ORDER BY tag')) {
      tags[row.columnAt(0) as String] = row.columnAt(1) as int;
    }
    _db.execute('UPDATE col SET tags = ?', [jsonEncode(tags)]);
  }

  static const _deckConfigReservedKeys = <String>{
    'id',
    'newSortOrder',
    'replayq',
    'newPerDayMinimum',
    'usn',
    'autoplay',
    'dyn',
    'maxTaken',
    'reviewOrder',
    'buryInterdayLearning',
    'newMix',
    'mod',
    'timer',
    'name',
    'interdayLearningMix',
    'newGatherPriority',
    'fsrsWeights',
    'fsrsParams5',
    'fsrsParams6',
    'desiredRetention',
    'stopTimerOnAnswer',
    'secondsToShowQuestion',
    'secondsToShowAnswer',
    'questionAction',
    'answerAction',
    'waitForAudio',
    'sm2Retention',
    'weightSearch',
    'ignoreRevlogsBeforeDate',
    'easyDaysPercentages',
  };

  static const _deckReservedKeys = <String>{
    'usn',
    'revToday',
    'newLimit',
    'dyn',
    'reviewLimit',
    'newToday',
    'timeToday',
    'reviewLimitToday',
    'extendNew',
    'mod',
    'newLimitToday',
    'desc',
    'name',
    'lrnToday',
    'conf',
    'browserCollapsed',
    'extendRev',
    'id',
    'collapsed',
    'desiredRetention',
    'return',
  };

  static const _notetypeReservedKeys = <String>{
    'latexPost',
    'flds',
    'css',
    'originalStockKind',
    'originalId',
    'id',
    'usn',
    'mod',
    'req',
    'latexPre',
    'name',
    'did',
    'tmpls',
    'type',
    'sortf',
    'latexsvg',
  };

  static const _fieldReservedKeys = <String>{
    'name',
    'ord',
    'sticky',
    'rtl',
    'plainText',
    'font',
    'size',
    'collapsed',
    'description',
    'excludeFromSearch',
    'id',
    'tag',
    'preventDeletion',
  };

  static const _templateReservedKeys = <String>{
    'name',
    'ord',
    'did',
    'afmt',
    'bafmt',
    'qfmt',
    'bqfmt',
    'bfont',
    'bsize',
    'id',
  };

  String _colString(String column) =>
      _db.select('SELECT $column FROM col').single.columnAt(0) as String;

  int _colInt(String column) =>
      _db.select('SELECT $column FROM col').single.columnAt(0) as int;
}

Map<String, Object?> _decodeJsonObject(String value) =>
    _jsonObject(jsonDecode(value), 'collection column');

Map<String, Object?> _jsonObject(Object? value, String description) {
  if (value is! Map) throw FormatException('$description must be an object');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

int _parseLegacyId(String value) => int.parse(value);

int _int(Object? value) => value is num ? value.toInt() : int.parse('$value');

int _num(Object? value, int defaultValue) => switch (value) {
  num number => number.toInt(),
  String string => int.tryParse(string) ?? defaultValue,
  _ => defaultValue,
};

int _strictEnumValue(
  Object? value, {
  required int maximum,
  required String label,
}) {
  if (value is int && value >= 0 && value <= maximum) return value;
  throw FormatException('invalid $label');
}

int _signed32(int value) => value >= 0x80000000 ? value - 0x100000000 : value;

double _numDouble(Object? value, double defaultValue) => switch (value) {
  num number => number.toDouble(),
  String string => double.tryParse(string) ?? defaultValue,
  _ => defaultValue,
};

bool _bool(Object? value, bool defaultValue) => switch (value) {
  bool boolean => boolean,
  num number => number != 0,
  String string =>
    string == 'true'
        ? true
        : string == 'false'
        ? false
        : defaultValue,
  _ => defaultValue,
};

Int64 _int64(Object? value) =>
    value is num ? Int64(value.toInt()) : Int64.parseInt('$value');

List<double> _numbers(Object? value, [List<double> defaults = const []]) =>
    value is List
    ? value.map((item) => _numDouble(item, 0)).toList(growable: false)
    : defaults;

List<int> _pair(Object? value) {
  if (value is! List || value.length < 2) return const [0, 0];
  return [_num(value[0], 0), _num(value[1], 0)];
}

Map<String, Object?> _withoutKeys(
  Map<String, Object?> values,
  Set<String> reserved,
) => {
  for (final entry in values.entries)
    if (!reserved.contains(entry.key)) entry.key: entry.value,
};

String _string(Object? value) => value is String ? value : '$value';

Uint8List _bytes(Object? value) => switch (value) {
  Uint8List bytes => bytes,
  List<int> bytes => Uint8List.fromList(bytes),
  _ => throw FormatException('expected SQLite blob'),
};

DateTime _migrationNow() => DateTime.now();
