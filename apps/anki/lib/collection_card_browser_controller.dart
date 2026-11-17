/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/anki_dart.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:fixnum/fixnum.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_browser_screen.dart';
import 'collection_runtime.dart';

/// Collection-backed Card Browser for the active profile.
///
/// It implements source-compatible card search and SQL sorting for the
/// supported query subset. Rendering, preferences, editing, preview, and bulk
/// operations remain separate ports until their Core behavior is connected.
final class CollectionCardBrowserController implements CardBrowserController {
  CollectionCardBrowserController(
    this.collections, {
    SharedPreferencesAsync? preferences,
  }) : _preferencesOverride = preferences;

  final CollectionRuntime collections;
  final SharedPreferencesAsync? _preferencesOverride;
  SharedPreferencesAsync get _preferences =>
      _preferencesOverride ?? SharedPreferencesAsync();
  static const _activeColumnsKey = 'activeCols';
  static const _noSortingKey = 'anki.browser.noSorting';
  static const _defaultColumns = ['noteFld', 'template', 'cardDue', 'deck'];
  static const _sortKeys = BrowserSortConfigKeys(
    columnKey: 'sortType',
    reverseKey: 'sortBackwards',
  );
  BrowserSortType _sortType = const BrowserSortNoOrdering();
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
    final noSorting = await _preferences.getBool(_noSortingKey) ?? false;
    _sortType = resolveBrowserSortType(
      noSorting: noSorting,
      config: {
        'sortType': _storage.readCollectionConfig('sortType'),
        'sortBackwards': _storage.readCollectionConfig('sortBackwards'),
      },
      configKeys: _sortKeys,
      availableColumnKeys: SearchSqlSortColumn.values.map(
        (column) => column.key,
      ),
    );
    return _search(_query);
  }

  @override
  Future<void> saveColumns(List<BrowserColumn> columns) async {
    await _preferences.setString(
      _activeColumnsKey,
      columns.map((c) => c.key).join('|'),
    );
  }

  @override
  Future<CardBrowserSnapshot> search(String query) {
    _query = query;
    return _search(query);
  }

  @override
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType) async {
    final plan = buildBrowserSortSavePlan(
      sortType: sortType,
      configKeys: _sortKeys,
    );
    for (final write in plan.collectionConfigWrites) {
      await _storage.writeCollectionConfig(write.key, write.value);
    }
    await _preferences.setBool(_noSortingKey, plan.cardBrowserNoSorting);
    _sortType = sortType;
    return _search(_query);
  }

  Future<CardBrowserSnapshot> _search(String query) async {
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
    final sortOrder = _compileSortOrder(_sortType);
    final plan = compileSearchSqlWithSort(
      root,
      resultType: SearchResultType.cards,
      deckIdsWithChildren: deckIdsWithChildren,
      sortOrder: sortOrder,
    );
    final ids = await storage.executeSearchPlan(plan);
    final cards = await storage.getCardsByIds(
      ids.map((id) => Int64.parseInt(id.toString())),
    );
    final cardsById = {for (final card in cards) card.id.toString(): card};
    final notes = await storage.getNotesByIds(
      cards.map((card) => card.noteId).toSet(),
    );
    final notesById = {for (final note in notes) note.id.toString(): note};
    final decksById = {for (final deck in decks) deck.id.toString(): deck};
    final configuredColumns = BrowserColumnCollection.load(
      preferenceValue: await _preferences.getString(_activeColumnsKey),
      defaultColumnKeys: _defaultColumns,
    );
    final rows = <CardBrowserRow>[];
    for (final id in ids) {
      final card = cardsById[id.toString()];
      if (card == null) throw StateError('Card $id disappeared during search.');
      final note = notesById[card.noteId.toString()];
      if (note == null) {
        throw StateError('Note ${card.noteId} disappeared during search.');
      }
      final deck = decksById[card.deckId.toString()];
      rows.add(
        CardBrowserRow(
          id: BrowserRowId.bigInt(id),
          cells: {
            for (final column in configuredColumns.columns)
              column.key: switch (column) {
                BrowserColumn.sortField =>
                  note.sortField ?? note.fields.firstOrNull ?? '',
                BrowserColumn.deck => deck?.name ?? '',
                BrowserColumn.tags => note.tags.join(' '),
                _ => 'Unavailable',
              },
          },
        ),
      );
    }
    return CardBrowserSnapshot(
      columns: [
        for (final column in configuredColumns.columns)
          CardBrowserColumn(type: column, label: _columnLabel(column)),
      ],
      rows: rows,
      sortType: _sortType,
    );
  }

  String _columnLabel(BrowserColumn column) => switch (column) {
    BrowserColumn.sortField => 'Sort field',
    BrowserColumn.deck => 'Deck',
    BrowserColumn.tags => 'Tags',
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
