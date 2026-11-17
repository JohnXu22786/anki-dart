/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_dart/anki_dart.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:fixnum/fixnum.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_browser_screen.dart';
import 'collection_runtime.dart';

/// Collection-backed Card Browser for the active profile.
///
/// It implements source-compatible card/note search and SQL sorting for the
/// supported query subset. Rendering, editing, preview, and bulk operations
/// remain separate ports until their Core behavior is connected.
final class CollectionCardBrowserController
    implements CardBrowserController, CardBrowserModeController {
  CollectionCardBrowserController(
    this.collections, {
    SharedPreferencesAsync? preferences,
  }) : _preferencesOverride = preferences;

  final CollectionRuntime collections;
  final SharedPreferencesAsync? _preferencesOverride;
  SharedPreferencesAsync get _preferences =>
      _preferencesOverride ?? SharedPreferencesAsync();
  static const _cardsColumnsKey = 'activeCols';
  static const _notesColumnsKey = 'activeNoteCols';
  static const _modeConfigKey = 'browserTableShowNotesMode';
  static const _noSortingKey = 'anki.browser.noSorting';
  static const _cardsDefaultColumns = [
    'noteFld',
    'template',
    'cardDue',
    'deck',
  ];
  static const _notesDefaultColumns = [
    'noteFld',
    'note',
    'template',
    'noteTags',
  ];
  static const _cardsSortKeys = BrowserSortConfigKeys(
    columnKey: 'sortType',
    reverseKey: 'sortBackwards',
  );
  static const _notesSortKeys = BrowserSortConfigKeys(
    columnKey: 'noteSortType',
    reverseKey: 'browserNoteSortBackwards',
  );
  BrowserSortType _sortType = const BrowserSortNoOrdering();
  BrowserColumnMode _mode = BrowserColumnMode.cards;
  bool _modeLoaded = false;
  CardBrowserSnapshot? _lastSnapshot;
  String _query = '';

  CollectionSqliteStorage get _storage {
    final storage = collections.storage;
    if (storage == null || !collections.isInitialized) {
      throw StateError('The active profile collection is not open.');
    }
    return storage;
  }

  @override
  Future<CardBrowserSnapshot> load() async {
    _mode = _readMode();
    _modeLoaded = true;
    await _loadSortType();
    return _search(_query);
  }

  BrowserColumnMode _readMode() =>
      _storage.readCollectionConfig(_modeConfigKey) == true
      ? BrowserColumnMode.notes
      : BrowserColumnMode.cards;

  Future<void> _loadSortType() async {
    final noSorting = await _preferences.getBool(_noSortingKey) ?? false;
    _sortType = resolveBrowserSortType(
      noSorting: noSorting,
      config: {
        _sortKeysFor(_mode).columnKey: _storage.readCollectionConfig(
          _sortKeysFor(_mode).columnKey,
        ),
        _sortKeysFor(_mode).reverseKey: _storage.readCollectionConfig(
          _sortKeysFor(_mode).reverseKey,
        ),
      },
      configKeys: _sortKeysFor(_mode),
      availableColumnKeys: SearchSqlSortColumn.values
          .where((column) => column != SearchSqlSortColumn.custom)
          .map((column) => column.key),
    );
  }

  BrowserSortConfigKeys _sortKeysFor(BrowserColumnMode mode) =>
      mode == BrowserColumnMode.cards ? _cardsSortKeys : _notesSortKeys;

  String _columnsKeyFor(BrowserColumnMode mode) =>
      mode == BrowserColumnMode.cards ? _cardsColumnsKey : _notesColumnsKey;

  List<String> _defaultColumnsFor(BrowserColumnMode mode) =>
      mode == BrowserColumnMode.cards
      ? _cardsDefaultColumns
      : _notesDefaultColumns;

  @override
  Future<void> saveColumns(List<BrowserColumn> columns) async {
    await _preferences.setString(
      _columnsKeyFor(_mode),
      columns.map((c) => c.key).join('|'),
    );
  }

  @override
  Future<CardBrowserSnapshot> updateMode(BrowserColumnMode mode) async {
    if (!_modeLoaded) {
      _mode = _readMode();
      _modeLoaded = true;
    }
    if (_mode == mode) {
      final snapshot = _lastSnapshot;
      return snapshot ?? _search(_query);
    }

    await _storage.writeCollectionConfig(
      _modeConfigKey,
      mode == BrowserColumnMode.notes,
    );
    _mode = mode;
    await _loadSortType();
    return _search(_query);
  }

  @override
  Future<CardBrowserSnapshot> search(String query) {
    _query = query;
    return _search(query);
  }

  /// Loads saved searches from this controller's active collection config.
  @override
  Future<List<BrowserSavedSearch>> loadSavedSearches() async {
    final values = _readSavedSearchConfigValues();
    return browserSavedSearchesFromConfigMap(values);
  }

  /// Adds a named search to this collection, trimming the query as AnkiDroid
  /// does. A duplicate exact name leaves collection config untouched.
  @override
  Future<(bool, List<BrowserSavedSearch>)> addSavedSearch(
    BrowserSavedSearch savedSearch,
  ) async {
    final model = BrowserSavedSearchesModel(
      configValues: _readSavedSearchConfigValues(),
    );
    final (changed, values) = model.add(savedSearch);
    if (!changed) return (false, values);
    await _storage.writeCollectionConfig(
      'savedFilters',
      browserSavedSearchesToConfigMap(values),
    );
    return (true, await loadSavedSearches());
  }

  /// Removes the exact name from this collection's saved searches.
  @override
  Future<(bool, List<BrowserSavedSearch>)> deleteSavedSearch(
    String name,
  ) async {
    final model = BrowserSavedSearchesModel(
      configValues: _readSavedSearchConfigValues(),
    );
    final (changed, values) = model.removeByName(name);
    if (!changed) return (false, values);
    await _storage.writeCollectionConfig(
      'savedFilters',
      browserSavedSearchesToConfigMap(values),
    );
    return (true, values);
  }

  Map<String, String> _readSavedSearchConfigValues() {
    final raw = _storage.readCollectionConfig('savedFilters');
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  @override
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType) async {
    final plan = buildBrowserSortSavePlan(
      sortType: sortType,
      configKeys: _sortKeysFor(_mode),
    );
    for (final write in plan.collectionConfigWrites) {
      await _storage.writeCollectionConfig(write.key, write.value);
    }
    await _preferences.setBool(_noSortingKey, plan.cardBrowserNoSorting);
    _sortType = sortType;
    return _search(_query);
  }

  Future<CardBrowserSnapshot> _search(String query) async {
    final mode = _mode;
    final sortType = _sortType;
    final storage = _storage;
    final selectedDeckId = storage.currentDeckId;
    final decks = storage.decks.getAllDecksInNameOrder();
    final deckIdsWithChildren = <BigInt, List<BigInt>>{
      for (final deck in decks)
        BigInt.parse(deck.id.toString()): [
          for (final childId in storage.decks.deckIdWithChildren(deck))
            BigInt.parse(childId.toString()),
        ],
    };
    final root = collectionCardBrowserSearchNode(query, selectedDeckId);
    final sortOrder = _compileSortOrder(sortType);
    final plan = compileSearchSqlWithSort(
      root,
      resultType: mode == BrowserColumnMode.cards
          ? SearchResultType.cards
          : SearchResultType.notes,
      deckIdsWithChildren: deckIdsWithChildren,
      sortOrder: sortOrder,
    );
    final ids = await storage.executeSearchPlan(plan);
    final cards = mode == BrowserColumnMode.cards
        ? await storage.getCardsByIds(
            ids.map((id) => Int64.parseInt(id.toString())),
          )
        : const <models.Card>[];
    final cardsById = {for (final card in cards) card.id.toString(): card};
    final noteIds = mode == BrowserColumnMode.notes
        ? ids.map((id) => Int64.parseInt(id.toString()))
        : cards.map((card) => card.noteId);
    final notes = await storage.getNotesByIds(noteIds.toSet());
    final notesById = {for (final note in notes) note.id.toString(): note};
    final notetypes = await storage.getNotetypesByIds(
      notes.map((note) => models.NotetypeId(note.notetypeId)),
    );
    final notetypesById = {
      for (final notetype in notetypes) notetype.id.toString(): notetype,
    };
    final decksById = {for (final deck in decks) deck.id.toString(): deck};
    final cardsByNoteId = mode == BrowserColumnMode.notes
        ? await storage.cardsOfNotes(notes.map((note) => note.id))
        : const <Int64, List<models.Card>>{};
    final configuredColumns = BrowserColumnCollection.load(
      preferenceValue: await _preferences.getString(_columnsKeyFor(mode)),
      defaultColumnKeys: _defaultColumnsFor(mode),
    );
    final rows = <CardBrowserRow>[];
    for (final id in ids) {
      final models.Card? card = mode == BrowserColumnMode.cards
          ? cardsById[id.toString()]
          : null;
      if (mode == BrowserColumnMode.cards && card == null) {
        throw StateError('Card $id disappeared during search.');
      }
      final noteId = mode == BrowserColumnMode.notes ? id : card!.noteId;
      final models.Note? note = notesById[noteId.toString()];
      if (note == null) {
        throw StateError('Note $noteId disappeared during search.');
      }
      final notetype = notetypesById[note.notetypeId.toString()];
      if (notetype == null) {
        throw StateError(
          'Notetype ${note.notetypeId} disappeared during search.',
        );
      }
      final deck = card == null ? null : decksById[card.deckId.toString()];
      rows.add(
        CardBrowserRow(
          id: BrowserRowId.bigInt(id),
          cells: {
            for (final column in configuredColumns.columns)
              column.key: _columnValue(
                column,
                note,
                card,
                deck,
                mode,
                cardsByNoteId[note.id] ?? const [],
                decksById,
                notetype,
              ),
          },
        ),
      );
    }
    final snapshot = CardBrowserSnapshot(
      columns: [
        for (final column in configuredColumns.columns)
          CardBrowserColumn(type: column, label: _columnLabel(column, mode)),
      ],
      rows: rows,
      sortType: sortType,
      mode: mode,
    );
    if (_mode == mode && _sortType == sortType) _lastSnapshot = snapshot;
    return snapshot;
  }

  String _columnValue(
    BrowserColumn column,
    models.Note note,
    models.Card? card,
    models.Deck? deck,
    BrowserColumnMode mode,
    List<models.Card> noteCards,
    Map<String, models.Deck> decksById,
    models.Notetype notetype,
  ) => switch (column) {
    BrowserColumn.question => _renderedCardSide(
      note,
      card,
      mode == BrowserColumnMode.cards ? const [] : noteCards,
      notetype,
      decksById,
      answer: false,
    ),
    BrowserColumn.answer => _renderedCardSide(
      note,
      card,
      mode == BrowserColumnMode.cards ? const [] : noteCards,
      notetype,
      decksById,
      answer: true,
    ),
    BrowserColumn.sortField => _sortField(note, notetype),
    BrowserColumn.noteType => notetype.name,
    BrowserColumn.cardType when mode == BrowserColumnMode.cards =>
      _templateName(notetype, card!),
    BrowserColumn.deck when mode == BrowserColumnMode.cards => deck?.name ?? '',
    BrowserColumn.deck => _notesDeckName(noteCards, decksById),
    BrowserColumn.cardType when mode == BrowserColumnMode.notes =>
      noteCards.length.toString(),
    BrowserColumn.tags => note.tags.join(' '),
    _ => 'Unavailable',
  };

  String _renderedCardSide(
    models.Note note,
    models.Card? selectedCard,
    List<models.Card> noteCards,
    models.Notetype notetype,
    Map<String, models.Deck> decksById, {
    required bool answer,
  }) {
    final card = selectedCard ?? _firstNoteCard(noteCards);
    if (card == null) return 'Unavailable';
    final deckId = card.originalDeckId.toInt() == 0
        ? card.deckId
        : card.originalDeckId;
    final sides = const models.BrowserCardTemplateRenderer().render(
      note: note,
      card: card,
      notetype: notetype,
      deckName: decksById[deckId.toString()]?.name ?? '(Deck)',
    );
    if (!sides.isAvailable) return 'Unavailable';
    final question = sides.questionHtml!;
    var html = answer ? sides.answerHtml! : question;
    if (answer && html.startsWith(question)) {
      html = html.substring(question.length);
    }
    return browserHtmlToTextLine(html, preserveMediaFilenames: true);
  }

  models.Card? _firstNoteCard(List<models.Card> cards) {
    // Core renders cards[0] from all_cards_of_note(), whose query has no
    // ORDER BY. Preserve the storage adapter's returned order here too.
    return cards.isEmpty ? null : cards.first;
  }

  String _sortField(models.Note note, models.Notetype notetype) {
    final index = notetype.config.sortFieldIdx;
    // Core indexes both arrays directly; invalid stored indexes are malformed
    // collection data and must fail the row projection rather than guess.
    final field = note.fields[index];
    notetype.fields[index];
    return browserHtmlToTextLine(field, preserveMediaFilenames: true);
  }

  String _templateName(models.Notetype notetype, models.Card card) {
    final template = notetype.isCloze
        ? notetype.templates.first
        : notetype.templates[card.templateIdx];
    return notetype.isCloze
        ? '${template.name} ${card.templateIdx + 1}'
        : template.name;
  }

  String _notesDeckName(
    List<models.Card> cards,
    Map<String, models.Deck> decksById,
  ) {
    final deckIds = cards.map((card) => card.deckId.toString()).toSet();
    if (deckIds.length > 1) return '(${deckIds.length})';
    if (deckIds.isEmpty) return '';
    return decksById[deckIds.first]?.name ?? '';
  }

  String _columnLabel(BrowserColumn column, BrowserColumnMode mode) =>
      switch (column) {
        BrowserColumn.question => 'Question',
        BrowserColumn.answer => 'Answer',
        BrowserColumn.sortField => 'Sort field',
        BrowserColumn.deck => 'Deck',
        BrowserColumn.tags => 'Tags',
        BrowserColumn.cardType when mode == BrowserColumnMode.notes => 'Cards',
        BrowserColumn.cardType => 'Card type',
        BrowserColumn.noteType => 'Note type',
        _ => '${column.key} (unavailable)',
      };

  SearchSqlSortOrder _compileSortOrder(BrowserSortType sortType) =>
      switch (sortType) {
        BrowserSortNoOrdering() => const SearchSqlSortOrder.none(),
        BrowserSortCollectionOrdering(:final key, :final reverse) => _sortOrder(
          key,
          reverse,
        ),
      };

  SearchSqlSortOrder _sortOrder(String key, bool reverse) {
    final column = SearchSqlSortColumn.values.where(
      (value) => value.key == key,
    );
    if (column.isEmpty || column.first == SearchSqlSortColumn.custom) {
      throw UnsupportedError('Card Browser sorting by "$key" is unavailable.');
    }
    return SearchSqlSortOrder.builtin(column.first, reverse: reverse);
  }

  @override
  Future<void> openColumnOptions(BrowserColumn column) async {}

  @override
  Future<void> manageColumns() async {}

  @override
  Future<void> updateSelection(List<BrowserRowId> selectedRows) async {}

  @override
  Future<void> preview(BrowserRowId rowId) =>
      Future.error(UnsupportedError('Card preview is not implemented.'));

  @override
  Future<void> edit(BrowserRowId rowId) =>
      Future.error(UnsupportedError('The Note Editor is not implemented.'));

  @override
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> selectedRows,
  ) => Future.error(
    UnsupportedError('Card Browser bulk actions are not implemented.'),
  );
}

/// Projects note-field HTML with Anki Core's `html_to_text_line(..., true)`
/// behavior used by the Browser sort-field column.
String browserHtmlToTextLine(
  String html, {
  required bool preserveMediaFilenames,
}) {
  var text = html.replaceAll(
    RegExp(r'<br\s*/?>|<div>|\n', caseSensitive: false),
    ' ',
  );
  if (preserveMediaFilenames) {
    text = text.replaceAllMapped(
      RegExp(
        r'''<\b(?:img|audio|video|object|source)\b(?:[^>]|"[^"]+?"|'[^']+?')+?\b(?:src|data)=(?:"([^"]+?)"[^>]*>|'([^']+?)'[^>]*>|([^ >]+?)(?:\x20[^>]*>|>))''',
        caseSensitive: false,
      ),
      (match) => ' ${match[1] ?? match[2] ?? match[3]} ',
    );
  }
  text = text
      .replaceAll(RegExp(r'\[\[type:[^\]]+\]\]'), '')
      .replaceAllMapped(
        RegExp(r'\[sound:([^\]]+)\]'),
        (match) => preserveMediaFilenames ? match[1]! : '',
      )
      .replaceAll(
        RegExp(
          r'<!--.*?-->|<style.*?>.*?</style>|<script.*?>.*?</script>|<.*?>',
          dotAll: true,
          caseSensitive: false,
        ),
        '',
      );
  // The shared field-text helper uses Core's strict htmlescape 0.3.1 decoder.
  // Markup has already been removed above, so its media stripping is a no-op.
  return models.stripHtmlPreservingMediaFilenames(text).trim();
}

/// Combines the user's complete query with the selected-deck constraint.
///
/// Grouping the query first preserves its `OR` precedence when the selected
/// deck constraint is applied to every matching branch.
Node collectionCardBrowserSearchNode(String query, Int64 selectedDeckId) {
  final queryNodes = parse(query);
  if (selectedDeckId == Int64.ZERO) return GroupNode(queryNodes);
  return GroupNode([
    if (queryNodes.isNotEmpty) GroupNode(queryNodes),
    if (queryNodes.isNotEmpty) const BooleanNode(NodeKind.and),
    Search(DeckIdWithChildren(selectedDeckId)),
  ]);
}
