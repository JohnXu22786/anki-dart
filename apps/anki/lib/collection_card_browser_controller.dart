/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:math';

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_backend_protocol/anki/notes.pbenum.dart' as note_proto;
import 'package:anki_dart/anki_dart.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_row_metadata.dart';
import 'card_browser_screen.dart';
import 'card_browser_preview.dart';
import 'browser_row_values.dart';
import 'collection_runtime.dart';
import 'l10n/app_localizations_en.dart';
import 'note_editor_screen.dart';

/// Collection-backed Card Browser for the active profile.
///
/// It implements source-compatible card/note search and SQL sorting for the
/// supported query subset. Existing-note field editing uses the same
/// collection adapter as browser reads; preview and bulk operations remain
/// separate ports.
final class CollectionCardBrowserController
    implements
        CardBrowserController,
        CardBrowserNoteEditorController,
        CardBrowserNewNoteEditorController,
        CardBrowserNoteUpdateUndoController,
        CardBrowserCollectionUndoController,
        CardBrowserModeController,
        CardBrowserSearchRequestController,
        CardBrowserSearchHistoryController,
        CardBrowserSearchHistoryDisplayController,
        CardBrowserSearchFilterOptionsController,
        CardBrowserDeckSelectionController,
        CardBrowserPreviewController {
  CollectionCardBrowserController(
    this.collections, {
    SharedPreferencesAsync? preferences,
    CardBrowserPreviewLoader? previewLoader,
    this.selectedNewNoteDeckId,
  }) : _preferencesOverride = preferences {
    _previewLoader =
        previewLoader ?? CollectionCardBrowserPreviewLoader(collections);
  }

  final CollectionRuntime collections;
  final AppLocalizationsEn _l10n = AppLocalizationsEn();
  final SharedPreferencesAsync? _preferencesOverride;
  final Int64? Function()? selectedNewNoteDeckId;
  late final CardBrowserPreviewLoader _previewLoader;
  SharedPreferencesAsync get _preferences =>
      _preferencesOverride ?? SharedPreferencesAsync();
  static const _cardsColumnsKey = 'activeCols';
  static const _notesColumnsKey = 'activeNoteCols';
  static const _modeConfigKey = 'browserTableShowNotesMode';
  static const _noSortingKey = 'anki.browser.noSorting';
  static const _searchHistoryKey = 'anki.browser.searchHistory';
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
  List<BrowserRowId> _selectedRows = const [];
  String _query = '';
  BrowserSearchRequest _activeRequest = const BrowserSearchRequest(query: '');
  Future<void> _historyWriteTail = Future<void>.value();
  bool _noteUpdateUndoPending = false;
  Int64 _selectedBrowserDeckId = Int64.ZERO;
  Int64? _launchDeckId;
  bool _launchIntentConsumed = true;
  bool _browserDeckInitialized = false;
  static final BigInt _allDecksLastId = BigInt.from(-1);
  static const _lastDeckIdKey = 'anki.browser.lastDeckId';

  CollectionSqliteStorage get _storage {
    final storage = collections.storage;
    if (storage == null || !collections.isInitialized) {
      throw StateError('The active profile collection is not open.');
    }
    return storage;
  }

  @override
  Future<CardBrowserSnapshot> load() async {
    await _initializeSelectedBrowserDeck();
    _mode = _readMode();
    _modeLoaded = true;
    await _loadSortType();
    return _search(_query);
  }

  @override
  Future<void> initializeBrowser({required Int64? launchDeckId}) async {
    _launchDeckId = launchDeckId;
    _launchIntentConsumed = false;
    _browserDeckInitialized = false;
  }

  @override
  Future<Int64?> loadSelectedBrowserDeck() async {
    if (!_browserDeckInitialized) await _initializeSelectedBrowserDeck();
    return _selectedBrowserDeckId == Int64.ZERO ? null : _selectedBrowserDeckId;
  }

  @override
  Future<String?> loadSelectedBrowserDeckName() async {
    final id = await loadSelectedBrowserDeck();
    if (id == null) return null;
    return _storage.decks.getDeck(id)?.name;
  }

  Future<void> _initializeSelectedBrowserDeck() async {
    if (_browserDeckInitialized) return;
    final storage = _storage;
    final decks = storage.decks.getAllDecksInNameOrder();
    final launchIntentConsumed = _launchIntentConsumed;
    final requestedLaunchDeckId = launchIntentConsumed ? null : _launchDeckId;
    if (!launchIntentConsumed) {
      _launchIntentConsumed = true;
      _launchDeckId = null;
    }
    BrowserDeckSelection selectionFor(Int64 id) {
      final deck = storage.decks.getDeck(id);
      if (deck == null) throw StateError('Card Browser deck no longer exists.');
      return BrowserDeckSelection(BigInt.parse(id.toString()), deck.name);
    }

    final currentDeckId = storage.currentDeckId;
    final currentDeck = storage.decks.getDeck(currentDeckId) == null
        ? (storage.decks.getDeck(Int64.ONE) == null
              ? decks.first
              : storage.decks.getDeck(Int64.ONE)!)
        : storage.decks.getDeck(currentDeckId)!;
    final rawLastDeckId = await _preferences.getString(_lastDeckIdKey);
    final BigInt? lastDeckId = rawLastDeckId == null
        ? null
        : BigInt.tryParse(rawLastDeckId);
    Int64? validLastDeckId;
    if (lastDeckId != null && lastDeckId != _allDecksLastId) {
      try {
        final candidate = Int64.parseInt(lastDeckId.toString());
        if (storage.decks.getDeck(candidate) != null) {
          validLastDeckId = candidate;
        }
      } on Object {
        // Malformed or out-of-range stored values fall back to the collection.
      }
    }
    final validLastDeck = validLastDeckId == null
        ? null
        : selectionFor(validLastDeckId);
    final intentDeckId = requestedLaunchDeckId;
    final intentDeck =
        intentDeckId != null && storage.decks.getDeck(intentDeckId) != null
        ? selectionFor(intentDeckId)
        : null;
    final plan = planBrowserInitialDeck(
      launchIntentConsumed: launchIntentConsumed,
      intentDeck: intentDeck,
      lastDeckId: lastDeckId,
      allDecksId: _allDecksLastId,
      validLastDeck: validLastDeck,
      currentSelectedDeck: selectionFor(currentDeck.id),
    );
    _selectedBrowserDeckId = switch (plan.selectedDeck) {
      BrowserAllDecksSelection() => Int64.ZERO,
      BrowserDeckSelection(:final id) => Int64.parseInt(id.toString()),
    };
    final updatePlan = planBrowserSelectedDeckUpdate(
      selectedDeck: switch (plan.selectedDeck) {
        BrowserAllDecksSelection() => const BrowserSelectAllDecks(),
        BrowserDeckSelection(:final id, :final name) =>
          BrowserSelectSpecificDeck(
            id: id,
            deckNameId: BrowserDeckNameId(name: name, id: id),
          ),
      },
      allDecksId: _allDecksLastId,
      currentRequest: _activeRequest,
    );
    _query = updatePlan.updatedRequest.query;
    _activeRequest = updatePlan.updatedRequest;
    await _preferences.setString(
      _lastDeckIdKey,
      updatePlan.lastDeckId.toString(),
    );
    _browserDeckInitialized = true;
  }

  @override
  Future<CardBrowserSnapshot> selectBrowserDeck(Int64? deckId) async {
    final storage = _storage;
    final selectedDeck = deckId == null
        ? const BrowserSelectAllDecks()
        : () {
            final deck = storage.decks.getDeck(deckId);
            if (deck == null) {
              throw StateError('Card Browser deck no longer exists.');
            }
            return BrowserSelectSpecificDeck(
              id: BigInt.parse(deck.id.toString()),
              deckNameId: BrowserDeckNameId(
                name: deck.name,
                id: BigInt.parse(deck.id.toString()),
              ),
            );
          }();
    final plan = planBrowserSelectedDeckUpdate(
      selectedDeck: selectedDeck,
      allDecksId: _allDecksLastId,
      currentRequest: _activeRequest,
    );
    final unchangedSelection =
        _selectedBrowserDeckId == (deckId ?? Int64.ZERO) &&
        plan.updatedRequest == _activeRequest;
    await _preferences.setString(_lastDeckIdKey, plan.lastDeckId.toString());
    _selectedBrowserDeckId = deckId ?? Int64.ZERO;
    _query = plan.updatedRequest.query;
    _activeRequest = plan.updatedRequest;
    if (unchangedSelection && _lastSnapshot != null) return _lastSnapshot!;
    return _searchRequest(plan.updatedRequest);
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
      availableColumnKeys: BrowserColumn.values
          .where((column) => column.canSort(_mode))
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
  Future<CardBrowserSnapshot> search(String query) =>
      searchRequest(BrowserSearchRequest(query: query));

  @override
  Future<CardBrowserSnapshot> searchRequest(
    BrowserSearchRequest request,
  ) async {
    _query = request.query;
    _activeRequest = request;
    await _serializeHistoryChange(() async {
      final history = BrowserSearchHistoryModel(entries: await _readHistory());
      final effects = browserSubmitCurrentSearchEffects(
        request,
        history: history,
      );
      final historyEffect = effects.first as BrowserSearchHistoryLoadingEffect;
      await _preferences.setString(
        _searchHistoryKey,
        BrowserSearchHistoryJsonCodec.encode(historyEffect.history.input),
      );
    });
    return _searchRequest(request);
  }

  Future<T> _serializeHistoryChange<T>(Future<T> Function() change) {
    final result = _historyWriteTail.then((_) => change());
    _historyWriteTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  @override
  Future<List<BrowserSearchHistoryEntry>> loadSearchHistory() => _readHistory();

  @override
  Future<List<CardBrowserSearchHistoryDisplayItem>>
  loadSearchHistoryDisplayItems(List<BrowserSearchHistoryEntry> entries) async {
    if (entries.isEmpty) return const [];

    try {
      final storage = _storage;
      final decks = storage.decks.getAllDecksInNameOrder();
      final deckNameMap = [
        for (final deck in decks)
          BrowserDeckNameId(
            name: deck.name,
            id: BigInt.parse(deck.id.toString()),
          ),
      ];
      final noteTypeIds = {
        for (final entry in entries)
          for (final id in entry.noteTypeIds) _toInt64(id),
      };
      final noteTypes = await storage.getNotetypesByIds(
        noteTypeIds.map(models.NotetypeId.new),
      );
      final noteTypeMap = [
        for (final notetype in noteTypes)
          BrowserNoteTypeNameId(
            name: notetype.name,
            id: BigInt.parse(notetype.id.toString()),
          ),
      ];

      return [
        for (final entry in entries)
          _historyDisplayItem(
            entry,
            deckNameMap: deckNameMap,
            noteTypeMap: noteTypeMap,
          ),
      ];
    } catch (_) {
      return [for (final entry in entries) _historyDisplayFallback(entry)];
    }
  }

  CardBrowserSearchHistoryDisplayItem _historyDisplayItem(
    BrowserSearchHistoryEntry entry, {
    required List<BrowserDeckNameId> deckNameMap,
    required List<BrowserNoteTypeNameId> noteTypeMap,
  }) {
    final request = BrowserSearchRequest.fromHistoryEntry(
      entry,
      deckNameMap: deckNameMap,
      noteTypeMap: noteTypeMap,
    );
    if (request == null) return _historyDisplayFallback(entry);

    try {
      final searchString = browserSearchString(request);
      return (
        searchString: searchString.isEmpty ? null : searchString,
        includesStructuredFilters:
            request.filters != const BrowserSearchFilters(),
      );
    } catch (_) {
      return _historyDisplayFallback(entry);
    }
  }

  CardBrowserSearchHistoryDisplayItem _historyDisplayFallback(
    BrowserSearchHistoryEntry entry,
  ) => (
    searchString: entry.query.isEmpty ? null : entry.query,
    includesStructuredFilters: false,
  );

  Future<List<BrowserSearchHistoryEntry>> _readHistory() async {
    final stored = await _preferences.getString(_searchHistoryKey) ?? '[]';
    try {
      return BrowserSearchHistoryJsonCodec.decode(stored);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeHistory(List<BrowserSearchHistoryEntry> entries) async {
    await _preferences.setString(
      _searchHistoryKey,
      BrowserSearchHistoryJsonCodec.encode(entries),
    );
  }

  @override
  Future<void> removeSearchHistoryEntry(BrowserSearchHistoryEntry entry) =>
      _serializeHistoryChange(() async {
        final history = BrowserSearchHistoryModel(
          entries: await _readHistory(),
        );
        if (history.removeEntry(entry)) await _writeHistory(history.entries);
      });

  @override
  Future<void> clearSearchHistory() =>
      _serializeHistoryChange(() => _writeHistory(const []));

  @override
  Future<BrowserSearchRequest> restoreSearchHistoryEntry(
    BrowserSearchHistoryEntry entry,
  ) async {
    final decks = _storage.decks.getAllDecksInNameOrder();
    final deckNameMap = [
      for (final deck in decks)
        BrowserDeckNameId(
          name: deck.name,
          id: BigInt.parse(deck.id.toString()),
        ),
    ];
    final notetypeIds = entry.noteTypeIds.map(_toInt64).toSet();
    final notetypes = await _storage.getNotetypesByIds(
      notetypeIds.map(models.NotetypeId.new),
    );
    final noteTypeMap = [
      for (final notetype in notetypes)
        BrowserNoteTypeNameId(
          name: notetype.name,
          id: BigInt.parse(notetype.id.toString()),
        ),
    ];
    final request =
        BrowserSearchRequest.fromHistoryEntry(
          entry,
          deckNameMap: deckNameMap,
          noteTypeMap: noteTypeMap,
        ) ??
        BrowserSearchRequest(query: entry.query);
    final restoredDeck = request.filters.decks.firstOrNull;
    _selectedBrowserDeckId = restoredDeck == null
        ? Int64.ZERO
        : Int64.parseInt(restoredDeck.id.toString());
    _browserDeckInitialized = true;
    // History can also populate the search editor without submitting. Keep
    // the active request synchronized so a later deck choice preserves it.
    _query = request.query;
    _activeRequest = request;
    return request;
  }

  @override
  Future<CardBrowserSearchFilterOptions> loadSearchFilterOptions() async {
    final storage = _storage;
    final decks = storage.decks.getAllDecksInNameOrder();
    final noteTypeIds = await storage.getAllNotetypeIds();
    final noteTypes = await storage.getNotetypesByIds(noteTypeIds);
    return CardBrowserSearchFilterOptions(
      decks: [
        for (final deck in decks)
          BrowserDeckNameId(
            name: deck.name,
            id: BigInt.parse(deck.id.toString()),
          ),
      ],
      noteTypes: [
        for (final noteType in noteTypes)
          BrowserNoteTypeNameId(
            name: noteType.name,
            id: BigInt.parse(noteType.id.toString()),
          ),
      ],
      tags: storage.tags.allTags().map((tag) => tag.name).toList(),
    );
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
    if (sortType case BrowserSortCollectionOrdering(:final key)
        when !browserSortKeyAvailable(key, _mode)) {
      throw UnsupportedError('Card Browser sorting by "$key" is unavailable.');
    }
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

  Future<CardBrowserSnapshot> _search(String query) => _searchRequest(
    query == _activeRequest.query
        ? _activeRequest
        : BrowserSearchRequest(query: query),
  );

  Future<CardBrowserSnapshot> _searchRequest(
    BrowserSearchRequest request,
  ) async {
    final mode = _mode;
    final sortType = _sortType;
    final storage = _storage;
    final timing = storage.timingTodayForNow();
    final learnAheadSecs = storage.readCollectionConfig('collapseTime');
    // A restored structured search may carry several deck filters. The source
    // projects its first deck into the selector but searches the full filter
    // list; do not intersect that list with the selector's first deck.
    final selectedDeckId = request.filters.decks.isNotEmpty
        ? Int64.ZERO
        : _browserDeckInitialized
        ? _selectedBrowserDeckId
        : storage.currentDeckId;
    final decks = storage.decks.getAllDecksInNameOrder();
    final deckIdsWithChildren = <BigInt, List<BigInt>>{
      for (final deck in decks)
        BigInt.parse(deck.id.toString()): [
          for (final childId in storage.decks.deckIdWithChildren(deck))
            BigInt.parse(childId.toString()),
        ],
    };
    final root = collectionCardBrowserSearchNodeForRequest(
      request,
      selectedDeckId,
    );
    final sortOrder = _compileSortOrder(sortType);
    final plan = compileSearchSqlWithSort(
      root,
      resultType: mode == BrowserColumnMode.cards
          ? SearchResultType.cards
          : SearchResultType.notes,
      timing: SearchSqlTiming(
        daysElapsed: timing.daysElapsed,
        now: BigInt.from(timing.now),
        learnAheadSecs: learnAheadSecs is int ? learnAheadSecs : 1200,
        nextDayAt: BigInt.from(timing.nextDayAt),
      ),
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
      final rowCards = mode == BrowserColumnMode.notes
          ? cardsByNoteId[note.id] ?? const <models.Card>[]
          : [card!];
      final rowError = mode == BrowserColumnMode.notes && rowCards.isEmpty
          ? BrowserRowError.databaseCheckRequired
          : null;
      final metadataCard = rowCards.isEmpty ? null : rowCards.first;
      final metadata = browserRowMetadata(
        mode: mode,
        note: note,
        notetype: notetype,
        card: metadataCard,
        columns: configuredColumns.columns,
      );
      final rowValues = browserRowValues(
        cards: rowCards,
        note: note,
        mode: mode,
        timing: timing,
        l10n: _l10n,
      );
      rows.add(
        CardBrowserRow(
          id: BrowserRowId.bigInt(id),
          fontName: metadata.fontName,
          fontSize: metadata.fontSize,
          color: rowError == null
              ? metadata.color
              : CardBrowserRowColor.unknown,
          error: rowError,
          rtlCells: metadata.rtlCells,
          elideModes: metadata.elideModes,
          cells: rowError != null
              ? {
                  for (final column in configuredColumns.columns)
                    column.key: _rowErrorMessage(rowError),
                }
              : {
                  for (final column in configuredColumns.columns)
                    column.key: _columnValue(
                      column,
                      note,
                      card,
                      deck,
                      mode,
                      rowCards,
                      decksById,
                      notetype,
                      rowValues,
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

  String _rowErrorMessage(BrowserRowError error) => switch (error) {
    BrowserRowError.databaseCheckRequired => _l10n.browserDatabaseCheckRequired,
  };

  String _columnValue(
    BrowserColumn column,
    models.Note note,
    models.Card? card,
    models.Deck? deck,
    BrowserColumnMode mode,
    List<models.Card> noteCards,
    Map<String, models.Deck> decksById,
    models.Notetype notetype,
    Map<String, String> rowValues,
  ) {
    final projectedValue = rowValues[column.key];
    if (projectedValue != null) return projectedValue;
    return switch (column) {
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
      BrowserColumn.deck when mode == BrowserColumnMode.cards =>
        deck?.name ?? '',
      BrowserColumn.deck => _notesDeckName(noteCards, decksById),
      BrowserColumn.cardType when mode == BrowserColumnMode.notes =>
        noteCards.length.toString(),
      BrowserColumn.tags => note.tags.join(' '),
      _ => 'Unavailable',
    };
  }

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
        BrowserColumn.due => _l10n.browserColumnDue,
        BrowserColumn.ease =>
          mode == BrowserColumnMode.notes
              ? _l10n.browserColumnAverageEase
              : _l10n.browserColumnEase,
        BrowserColumn.changed => _l10n.browserColumnCardModified,
        BrowserColumn.created => _l10n.browserColumnCreated,
        BrowserColumn.edited => _l10n.browserColumnNoteModified,
        BrowserColumn.interval =>
          mode == BrowserColumnMode.notes
              ? _l10n.browserColumnAverageInterval
              : _l10n.browserColumnInterval,
        BrowserColumn.lapses => _l10n.browserColumnLapses,
        BrowserColumn.reviews => _l10n.browserColumnReviews,
        BrowserColumn.fsrsDifficulty => _l10n.browserColumnFsrsDifficulty,
        BrowserColumn.fsrsRetrievability =>
          _l10n.browserColumnFsrsRetrievability,
        BrowserColumn.fsrsStability => _l10n.browserColumnFsrsStability,
        BrowserColumn.originalPosition => _l10n.browserColumnOriginalPosition,
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
    if (!browserSortKeyAvailable(key, _mode)) {
      throw UnsupportedError('Card Browser sorting by "$key" is unavailable.');
    }
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
  Future<void> updateSelection(List<BrowserRowId> selectedRows) async {
    _selectedRows = List.unmodifiable(selectedRows);
  }

  @override
  Future<CardBrowserPreviewSession> loadPreview({
    required List<BrowserRowId> selectedRows,
  }) {
    final snapshot = _lastSnapshot;
    if (snapshot == null) {
      return Future.error(StateError('Card Browser results are unavailable.'));
    }
    final rows = snapshot.rows.map((row) => row.id).toList(growable: false);
    return _previewLoader.load(
      mode: snapshot.mode,
      rowIds: rows,
      selectedRows: selectedRows,
    );
  }

  @override
  Future<void> preview(BrowserRowId rowId) =>
      loadPreview(selectedRows: _selectedRows).then((_) {});

  @override
  Future<void> edit(BrowserRowId rowId) =>
      Future.error(UnsupportedError('The Note Editor is not implemented.'));

  @override
  Future<Int64> resolveNoteIdForRow(BrowserRowId rowId) async {
    final storage = _storage;
    final resolvedRowId = Int64.parseInt(rowId.bigValue.toString());
    final noteId = switch (_mode) {
      BrowserColumnMode.notes => resolvedRowId,
      BrowserColumnMode.cards => (await storage.getCard(resolvedRowId))?.noteId,
    };
    if (noteId == null || await storage.getNote(noteId) == null) {
      throw StateError('The selected browser row no longer has a note.');
    }

    final noteCardIds = _mode == BrowserColumnMode.notes
        ? (await storage.allCardIdsOfNoteInTemplateOrder(noteId))
              .map((id) => BigInt.parse(id.toString()))
              .toList(growable: false)
        : const <BigInt>[];
    final cardIds = browserEditorCardIdsBigInt(
      resolvedRowCardId: _mode == BrowserColumnMode.cards
          ? BigInt.parse(resolvedRowId.toString())
          : (noteCardIds.isEmpty ? null : noteCardIds.first),
      mode: _mode,
      isInMultiSelectMode: _selectedRows.isNotEmpty,
      noteCardIds: noteCardIds,
      selectedCardIds: _selectedRows
          .map((row) => row.bigValue)
          .toList(growable: false),
    );
    if (cardIds.isEmpty) {
      throw StateError('The selected note has no editable cards.');
    }
    final selectedCard = await storage.getCard(
      Int64.parseInt(cardIds.first.toString()),
    );
    if (selectedCard == null || selectedCard.noteId != noteId) {
      throw StateError('The selected browser row no longer has a note.');
    }
    return noteId;
  }

  @override
  Future<NoteEditorContent> loadNote(Int64 noteId) async {
    final storage = _storage;
    final note = await storage.getNote(noteId);
    if (note == null) throw StateError('Note does not exist.');
    final notetypes = await storage.getNotetypesByIds([
      models.NotetypeId(note.notetypeId),
    ]);
    final notetype = notetypes.where(
      (type) => type.id == models.NotetypeId(note.notetypeId),
    );
    if (notetype.isEmpty) throw StateError('Note type does not exist.');
    final fields = notetype.single.fields;
    return NoteEditorContent(
      labels: fields.map((field) => field.name).toList(growable: false),
      values: note.fields,
      tags: note.tags,
      availableTags: storage.tags.allTags().map((tag) => tag.name).toList(),
    );
  }

  @override
  Future<NewNoteEditorDraft> loadNewNote() async {
    final storage = _storage;
    final allTypes = await storage.getNotetypesByIds(
      await storage.getAllNotetypeIds(),
    );
    if (allTypes.isEmpty) throw StateError('The collection has no note types.');
    final typeById = {for (final type in allTypes) type.id.value: type};
    final currentDeck = storage.currentDeckId;
    final deck = storage.decks.getDeck(currentDeck);
    final deckNotetypeId = deck == null
        ? null
        : _legacyDeckNotetypeId(deck.common.other);
    final validDeckNotetypeId =
        deckNotetypeId != null && typeById.containsKey(deckNotetypeId)
        ? deckNotetypeId
        : null;
    final configuredTypeId =
        validDeckNotetypeId ?? storage.readCollectionConfigInt64('curModel');
    final notetype =
        typeById[configuredTypeId] ??
        typeById[Int64.ONE] ??
        (List<models.Notetype>.of(allTypes)..sort(
              (left, right) =>
                  left.name.toLowerCase().compareTo(right.name.toLowerCase()),
            ))
            .first;

    final useCurrentDeck = storage.readCollectionConfig('addToCur') != false;
    final rememberedDeck = storage.readCollectionConfigInt64(
      '_nt_${notetype.id.value}_lastDeck',
    );
    final fallbackDeck = useCurrentDeck
        ? _usableDeck(storage, currentDeck)
        : _usableDeck(storage, rememberedDeck ?? currentDeck);
    final requestedDeck = selectedNewNoteDeckId?.call();
    final selectedDeck =
        requestedDeck != null &&
            requestedDeck != Int64.ZERO &&
            _usableDeck(storage, requestedDeck) == requestedDeck
        ? requestedDeck
        : fallbackDeck;
    final note = models.Note.newNote(
      notetype,
      randomU64: () {
        final random = Random.secure();
        return (BigInt.from(random.nextInt(0x100000000)) << 32) |
            BigInt.from(random.nextInt(0x100000000));
      },
    );
    return NewNoteEditorDraft(
      notetypeId: notetype.id.value,
      deckId: selectedDeck,
      note: note,
      content: NoteEditorContent(
        labels: notetype.fields.map((field) => field.name).toList(),
        values: note.fields,
        availableTags: storage.tags.allTags().map((tag) => tag.name).toList(),
      ),
    );
  }

  @override
  Future<NoteFieldsCheckResult> validateNewNote(
    Int64 notetypeId,
    List<String> fields,
  ) async {
    final storage = _storage;
    final values = await storage.getNotetypesByIds([
      models.NotetypeId(notetypeId),
    ]);
    if (values.isEmpty) throw StateError('Note type does not exist.');
    final note = models.Note(notetypeId: notetypeId, fields: fields);
    final normalize =
        storage.readCollectionConfig('normalize_note_text') ??
        storage.readCollectionConfig('normalizeNoteText');
    final state = models.noteFieldsCheck(
      note: note,
      getNotetype: (_) => values.single,
      normalizeText: normalize is bool ? normalize : true,
      loadFieldsByChecksum: storage.getNoteFieldsByChecksum,
    );
    final status = switch (state) {
      note_proto.NoteFieldsCheckResponse_State.NORMAL =>
        NoteFieldsCheckStatus.normal,
      note_proto.NoteFieldsCheckResponse_State.DUPLICATE =>
        NoteFieldsCheckStatus.duplicate,
      note_proto.NoteFieldsCheckResponse_State.EMPTY =>
        NoteFieldsCheckStatus.empty,
      note_proto.NoteFieldsCheckResponse_State.MISSING_CLOZE =>
        NoteFieldsCheckStatus.missingCloze,
      note_proto.NoteFieldsCheckResponse_State.NOTETYPE_NOT_CLOZE =>
        NoteFieldsCheckStatus.noteTypeNotCloze,
      note_proto.NoteFieldsCheckResponse_State.FIELD_NOT_CLOZE =>
        NoteFieldsCheckStatus.fieldNotCloze,
      _ => NoteFieldsCheckStatus.unrecognized,
    };
    return projectNoteFieldsCheckResult(
      status: status,
      isImageOcclusion: false,
      messages: NoteFieldsCheckMessages(
        imageOcclusionEmpty: _l10n.noteEditorFirstFieldEmpty,
        firstFieldEmpty: _l10n.noteEditorFirstFieldEmpty,
        missingCloze: _l10n.noteEditorMissingCloze,
        noteTypeNotCloze: _l10n.noteEditorNoteTypeNotCloze,
        fieldNotCloze: _l10n.noteEditorFieldNotCloze,
      ),
    );
  }

  @override
  Future<int> saveNewNote({
    required NewNoteEditorDraft draft,
    required List<String> fields,
    required List<String> tags,
  }) async {
    final storage = _storage;
    final note = draft.note;
    if (note == null || note.notetypeId != draft.notetypeId) {
      throw StateError('New-note draft is no longer valid.');
    }
    if (note.id != Int64.ZERO) {
      // addNoteToDeck commits before its async driver flush. If that flush
      // failed, retry persistence then reconcile any edits made after the
      // failed save without adding the note or its cards twice.
      await storage.flushPendingWrites();
      await saveNote(note.id, fields, tags);
      return (await storage.allCardIdsOfNoteInTemplateOrder(note.id)).length;
    }
    note.fieldsMut()
      ..clear()
      ..addAll(fields);
    note.tags
      ..clear()
      ..addAll(tags);
    final result = await storage.addNoteToDeck(note, draft.deckId);
    return result.generatedCardCount;
  }

  Int64? _configInt64(Object? value) {
    if (value is int) return Int64(value);
    if (value is String) {
      try {
        return Int64.parseInt(value);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  Int64? _legacyDeckNotetypeId(List<int> other) {
    if (other.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(other));
      return decoded is Map ? _configInt64(decoded['mid']) : null;
    } catch (_) {
      return null;
    }
  }

  Int64 _usableDeck(CollectionSqliteStorage storage, Int64? deckId) {
    final deck = deckId == null ? null : storage.decks.getDeck(deckId);
    if (deck?.configId != null) return deckId!;
    final defaultDeck = storage.decks.getDeck(Int64.ONE);
    if (defaultDeck?.configId == null) {
      throw StateError('The collection has no usable default deck.');
    }
    return Int64.ONE;
  }

  @override
  Future<void> saveNote(
    Int64 noteId,
    List<String> fields,
    List<String> tags,
  ) async {
    final storage = _storage;
    final note = await storage.getNote(noteId);
    if (note == null) throw StateError('Note does not exist.');
    if (listEquals(note.fields, fields) && listEquals(note.tags, tags)) return;
    final noteFields = note.fieldsMut();
    noteFields
      ..clear()
      ..addAll(fields);
    note.tags
      ..clear()
      ..addAll(tags);
    await storage.updateExistingNote(note);
  }

  /// Compatibility entry point for callers which edit fields only.
  Future<void> saveFields(Int64 noteId, List<String> fields) async {
    final note = await _storage.getNote(noteId);
    if (note == null) throw StateError('Note does not exist.');
    await saveNote(noteId, fields, note.tags);
  }

  @override
  bool get canUndoNoteUpdate => _storage.existingNoteUpdateUndoStatus.canUndo;

  @override
  bool get noteUpdateUndoPending => _noteUpdateUndoPending;

  @override
  Future<void> undoLastNoteUpdate() async {
    if (_noteUpdateUndoPending) return;
    _noteUpdateUndoPending = true;
    try {
      await _storage.undoLastExistingNoteUpdate();
    } finally {
      _noteUpdateUndoPending = false;
    }
  }

  @override
  bool get canUndoCollectionOperation => _storage.canUndoCollectionOperation;

  @override
  int get collectionUndoGeneration => _storage.collectionUndoGeneration;

  @override
  Future<void> undoLastCollectionOperation() =>
      _storage.undoLastCollectionOperation();

  @override
  Future<CardBrowserSnapshot> refresh() => _searchRequest(_activeRequest);

  @override
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> selectedRows,
  ) async {
    final storage = _storage;
    if (selectedRows.isEmpty) return;
    final operationTimeMillis = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (action == CardBrowserBulkAction.delete) {
      late List<models.Note> notes;
      late Set<Int64> noteIds;
      late Map<Int64, List<models.Card>> cardsByNote;
      late List<models.Card> cards;
      late List<models.RevlogEntry> revlogs;
      late Map<Int64, bool> existingCardGraves;
      late Map<Int64, bool> existingNoteGraves;
      late Int64 mtimeBefore;
      final mtimeAfter = Int64(operationTimeMillis);
      final committed = await storage.runUndoableCollectionOperation(
        prepare: () async {
          // AnkiDroid resolves selected note rows to their card IDs before
          // calling Core's removeNotes. A selected note with no cards therefore
          // produces no deletion, matching the upstream behavior.
          final requestedNoteIds = (await storage.getCardsByIds(
            await _selectedCardIds(storage, selectedRows),
          )).map((card) => card.noteId).toSet();
          notes = await storage.getNotesByIds(requestedNoteIds);
          noteIds = notes.map((note) => note.id).toSet();
          if (noteIds.isEmpty) return false;
          cardsByNote = await storage.cardsOfNotes(noteIds);
          cards = [for (final noteId in noteIds) ...?cardsByNote[noteId]];
          revlogs = [
            for (final card in cards)
              ...storage.revlog.getRevlogEntriesForCard(card.id),
          ];
          existingCardGraves = {
            for (final card in cards)
              card.id: storage.hasDeletionGrave(card.id, note: false),
          };
          existingNoteGraves = {
            for (final noteId in noteIds)
              noteId: storage.hasDeletionGrave(noteId, note: true),
          };
          mtimeBefore = storage.collectionModifiedAt;
          return true;
        },
        apply: () async {
          for (final noteId in noteIds) {
            for (final card in cardsByNote[noteId] ?? const <models.Card>[]) {
              for (final entry in storage.revlog.getRevlogEntriesForCard(
                card.id,
              )) {
                storage.revlog.removeRevlogEntry(entry.id);
              }
              await storage.removeCard(card.id);
              storage.addDeletionGrave(card.id, note: false);
            }
            await storage.removeNote(noteId);
            storage.addDeletionGrave(noteId, note: true);
          }
          await storage.updateCollectionModifiedAt(Int64(operationTimeMillis));
        },
        undo: () async {
          for (final note in notes) {
            await storage.addOrUpdateNote(copyNote(note));
            if (existingNoteGraves[note.id] != true) {
              storage.removeDeletionGrave(note.id, note: true);
            }
          }
          for (final card in cards) {
            await storage.addOrUpdateCard(card);
            if (existingCardGraves[card.id] != true) {
              storage.removeDeletionGrave(card.id, note: false);
            }
          }
          for (final entry in revlogs) {
            storage.restoreRevlogEntry(entry);
          }
          storage.restoreCollectionModifiedAt(mtimeBefore);
        },
        redo: () async {
          for (final entry in revlogs) {
            storage.revlog.removeRevlogEntry(entry.id);
          }
          for (final card in cards) {
            await storage.removeCard(card.id);
            storage.addDeletionGrave(card.id, note: false);
          }
          for (final note in notes) {
            await storage.removeNote(note.id);
            storage.addDeletionGrave(note.id, note: true);
          }
          storage.restoreCollectionModifiedAt(mtimeAfter);
        },
      );
      if (!committed) return;
      await updateSelection(const []);
      return;
    }

    final modifiedAt = Int64(operationTimeMillis ~/ 1000);
    late List<models.Card> updates;
    late Map<Int64, models.Card> beforeById;
    late Int64 mtimeBefore;
    final mtimeAfter = Int64(operationTimeMillis);
    Future<void> applyCards(Iterable<models.Card> values) async {
      for (final card in values) {
        await storage.updateCard(card);
      }
    }

    await storage.runUndoableCollectionOperation(
      prepare: () async {
        final cardIds = await _selectedCardIds(storage, selectedRows);
        if (cardIds.isEmpty) return false;

        final cards = await storage.getCardsByIds(cardIds);
        if (cards.isEmpty) return false;
        final allSuspended = cards.every(
          (card) => card.queue == models.CardQueue.suspended,
        );
        final allBuried = cards.every(
          (card) =>
              card.queue == models.CardQueue.schedBuried ||
              card.queue == models.CardQueue.userBuried,
        );
        final shouldRestore = action == CardBrowserBulkAction.suspend
            ? allSuspended
            : allBuried;
        updates = [];
        for (final card in cards) {
          final queue = switch (action) {
            CardBrowserBulkAction.suspend =>
              shouldRestore
                  ? _queueForType(card)
                  : card.queue == models.CardQueue.suspended
                  ? card.queue
                  : models.CardQueue.suspended,
            CardBrowserBulkAction.bury =>
              shouldRestore
                  ? _queueForType(card)
                  : card.queue == models.CardQueue.suspended
                  ? card.queue
                  : models.CardQueue.userBuried,
            CardBrowserBulkAction.delete => card.queue,
          };
          if (queue != card.queue) {
            updates.add(
              models.Card.fromProto(
                card.toProto()
                  ..queue = queue.value
                  ..usn = -1
                  ..mtimeSecs = modifiedAt,
              ),
            );
          }
        }
        if (updates.isEmpty) return false;
        beforeById = {for (final card in cards) card.id: card};
        mtimeBefore = storage.collectionModifiedAt;
        return true;
      },
      apply: () async {
        await applyCards(updates);
        await storage.updateCollectionModifiedAt(mtimeAfter);
      },
      undo: () async {
        await applyCards(beforeById.values);
        storage.restoreCollectionModifiedAt(mtimeBefore);
      },
      redo: () async {
        await applyCards(updates);
        storage.restoreCollectionModifiedAt(mtimeAfter);
      },
    );
  }

  Future<List<Int64>> _selectedCardIds(
    CollectionSqliteStorage storage,
    List<BrowserRowId> selectedRows,
  ) async {
    if (_mode == BrowserColumnMode.cards) {
      return selectedRows
          .map((row) => Int64.parseInt(row.bigValue.toString()))
          .toSet()
          .toList(growable: false);
    }
    final noteIds = selectedRows
        .map((row) => Int64.parseInt(row.bigValue.toString()))
        .toSet()
        .toList(growable: false);
    final cardsByNote = await storage.cardsOfNotes(noteIds);
    return [
      for (final noteId in noteIds)
        for (final card in cardsByNote[noteId] ?? const <models.Card>[])
          card.id,
    ];
  }

  models.CardQueue _queueForType(models.Card card) => switch (card.ctype) {
    models.CardType.newCard => models.CardQueue.newCard,
    models.CardType.review => models.CardQueue.review,
    models.CardType.learn || models.CardType.relearn =>
      card.due > 1000000000
          ? models.CardQueue.learn
          : models.CardQueue.dayLearn,
  };
}

/// Reads and renders the selected browser results from the active collection.
final class CollectionCardBrowserPreviewLoader
    implements CardBrowserPreviewLoader {
  const CollectionCardBrowserPreviewLoader(this.collections);

  final CollectionRuntime collections;

  @override
  Future<CardBrowserPreviewSession> load({
    required BrowserColumnMode mode,
    required List<BrowserRowId> rowIds,
    required List<BrowserRowId> selectedRows,
  }) async {
    final storage = collections.storage;
    if (!collections.isInitialized || storage == null) {
      throw StateError('The active profile collection is not open.');
    }
    if (rowIds.isEmpty) throw StateError('Card Browser results are empty.');

    final cardsByNoteId = <String, List<models.Card>>{};
    if (mode == BrowserColumnMode.notes) {
      final noteIdsToLoad = <BigInt>{
        for (final row in rowIds) row.bigValue,
        for (final row in selectedRows) row.bigValue,
      };
      final cardsForNotes = await storage.cardsOfNotes(
        noteIdsToLoad.map((id) => Int64.parseInt(id.toString())),
      );
      for (final entry in cardsForNotes.entries) {
        cardsByNoteId[entry.key.toString()] = entry.value;
      }
      if (rowIds.any(
        (noteId) =>
            cardsByNoteId[noteId.bigValue.toString()]?.isNotEmpty != true,
      )) {
        throw StateError('A Card Browser note no longer has a preview card.');
      }
    }
    final payload = cardBrowserPreviewPayload(
      mode: mode,
      rowIds: rowIds,
      selectedRows: selectedRows,
      cardsByNoteId: {
        for (final entry in cardsByNoteId.entries)
          entry.key: [
            for (final card in entry.value) BigInt.parse(card.id.toString()),
          ],
      },
    );
    if (payload.cardIds.isEmpty) {
      throw StateError('The preview has no cards to show.');
    }
    if (payload.currentIndex < 0 ||
        payload.currentIndex >= payload.cardIds.length) {
      throw StateError('The selected Card Browser row is no longer available.');
    }

    final cards = await storage.getCardsByIds(
      payload.cardIds.map((id) => Int64.parseInt(id.toString())),
    );
    if (cards.length != payload.cardIds.length) {
      throw StateError('A preview card is no longer available.');
    }
    final notes = await storage.getNotesByIds(cards.map((card) => card.noteId));
    final notesById = {for (final note in notes) note.id.toString(): note};
    final notetypes = await storage.getNotetypesByIds(
      notes.map((note) => models.NotetypeId(note.notetypeId)),
    );
    final notetypesById = {
      for (final notetype in notetypes) notetype.id.toString(): notetype,
    };
    final decks = storage.decks.getAllDecksInNameOrder();
    final decksById = {for (final deck in decks) deck.id.toString(): deck};
    final previewCards = <CardBrowserPreviewCard>[];
    for (final card in cards) {
      final note = notesById[card.noteId.toString()];
      if (note == null) {
        throw StateError('A preview note is no longer available.');
      }
      final notetype = notetypesById[note.notetypeId.toString()];
      if (notetype == null) {
        throw StateError('A preview card template is no longer available.');
      }
      final deckId = card.originalDeckId.toInt() == 0
          ? card.deckId
          : card.originalDeckId;
      final sides = const models.BrowserCardTemplateRenderer().render(
        note: note,
        card: card,
        notetype: notetype,
        deckName: decksById[deckId.toString()]?.name ?? '(Deck)',
      );
      if (!sides.isAvailable) {
        throw StateError('The card template could not be rendered.');
      }
      previewCards.add(
        CardBrowserPreviewCard(
          id: BigInt.parse(card.id.toString()),
          questionHtml: sides.questionHtml!,
          answerHtml: sides.answerHtml!,
        ),
      );
    }
    return CardBrowserPreviewSession(
      cards: previewCards,
      currentIndex: payload.currentIndex,
    );
  }
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

/// Converts the source-derived structured request plan into the shared search
/// AST, keeping filter joins and selected-deck precedence explicit.
Node collectionCardBrowserSearchNodeForRequest(
  BrowserSearchRequest request,
  Int64 selectedDeckId,
) {
  final filters = request.filters;
  if (filters.decks.isEmpty &&
      filters.flags.isEmpty &&
      filters.tags.isEmpty &&
      filters.noteTypes.isEmpty &&
      filters.cardStateCodes.isEmpty) {
    return collectionCardBrowserSearchNode(request.query, selectedDeckId);
  }
  final planned = _browserSearchPlanNode(buildBrowserSearchNodePlan(request));
  if (selectedDeckId == Int64.ZERO) return planned;
  if (planned is GroupNode && planned.nodes.isEmpty) {
    return Search(DeckIdWithChildren(selectedDeckId));
  }
  return GroupNode([
    planned,
    const BooleanNode(NodeKind.and),
    Search(DeckIdWithChildren(selectedDeckId)),
  ]);
}

Node _browserSearchPlanNode(BrowserSearchNodePlan plan) => switch (plan) {
  BrowserSearchGroupPlan(:final joiner, :final children) => GroupNode([
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0)
        BooleanNode(
          joiner == BrowserSearchJoiner.and ? NodeKind.and : NodeKind.or,
        ),
      _browserSearchPlanNode(children[index]),
    ],
  ]),
  BrowserSearchTextTermPlan(:final text) => GroupNode(
    text.isEmpty ? const [] : parse(text),
  ),
  BrowserSearchDeckTermPlan(:final name) => Search(
    SearchNodeBuilder.fromDeckName(name),
  ),
  BrowserSearchFlagTermPlan(:final value) => Search(Flag(value.index)),
  BrowserSearchTagTermPlan(:final tag) => Search(
    SearchNodeBuilder.fromTagName(tag),
  ),
  BrowserSearchNoteTypeTermPlan(:final name) => Search(
    SearchNodeBuilder.fromNotetypeName(name),
  ),
  BrowserSearchCardStateTermPlan(:final value) => Search(
    State(switch (value) {
      BrowserSearchCardStateValue.newCard => StateKind.newCard,
      BrowserSearchCardStateValue.learning => StateKind.learning,
      BrowserSearchCardStateValue.review => StateKind.review,
      BrowserSearchCardStateValue.buried => StateKind.buried,
      BrowserSearchCardStateValue.suspended => StateKind.suspended,
    }),
  ),
};

Int64 _toInt64(Object id) => Int64.parseInt(id.toString());
