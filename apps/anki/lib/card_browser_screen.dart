/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'card_browser_row_colors.dart';
import 'card_browser_preview.dart';
import 'card_browser_preview_screen.dart';
import 'l10n/app_localizations.dart';
import 'note_editor_screen.dart';

export 'card_browser_row_colors.dart';

/// One host-projected column in the Card Browser table.
///
/// The backend supplies its current order and localized label. [type] connects
/// the display to AnkiDroid's shared column and sorting contracts.
final class CardBrowserColumn {
  const CardBrowserColumn({required this.type, required this.label});

  final BrowserColumn type;
  final String label;
}

/// A row with a stable card or note ID and host-rendered cell text.
final class CardBrowserRow {
  CardBrowserRow({
    required this.id,
    required Map<String, String> cells,
    this.fontName = '',
    this.fontSize = 0,
    this.color = CardBrowserRowColor.defaultColor,
    this.error,
    Map<String, bool> rtlCells = const {},
    Map<String, CardBrowserElideMode> elideModes = const {},
  }) : cells = Map.unmodifiable(cells),
       rtlCells = Map.unmodifiable(rtlCells),
       elideModes = Map.unmodifiable(elideModes);

  final BrowserRowId id;
  final Map<String, String> cells;
  final String fontName;
  final int fontSize;
  final CardBrowserRowColor color;
  final BrowserRowError? error;
  final Map<String, bool> rtlCells;
  final Map<String, CardBrowserElideMode> elideModes;
}

enum BrowserRowError { databaseCheckRequired }

enum CardBrowserElideMode { right, middle }

/// The immutable data shown by one completed Card Browser request.
final class CardBrowserSnapshot {
  CardBrowserSnapshot({
    required List<CardBrowserColumn> columns,
    required List<CardBrowserRow> rows,
    this.sortType = const BrowserSortNoOrdering(),
    this.mode = BrowserColumnMode.cards,
  }) : columns = List.unmodifiable(columns),
       rows = List.unmodifiable(rows);

  final List<CardBrowserColumn> columns;
  final List<CardBrowserRow> rows;
  final BrowserSortType sortType;
  final BrowserColumnMode mode;
}

enum CardBrowserBulkAction { suspend, bury, delete }

/// Backend and navigation boundary for the cross-platform Card Browser.
///
/// Implementations execute query/search, collection IO, sort persistence,
/// selection actions, preview, and editor navigation outside the widget.
abstract interface class CardBrowserController {
  Future<CardBrowserSnapshot> load();
  Future<CardBrowserSnapshot> search(String query);
  Future<List<BrowserSavedSearch>> loadSavedSearches();
  Future<(bool, List<BrowserSavedSearch>)> addSavedSearch(
    BrowserSavedSearch savedSearch,
  );
  Future<(bool, List<BrowserSavedSearch>)> deleteSavedSearch(String name);
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType);
  Future<void> openColumnOptions(BrowserColumn column);
  Future<void> manageColumns();
  Future<void> saveColumns(List<BrowserColumn> columns);
  Future<void> updateSelection(List<BrowserRowId> selectedRows);
  Future<void> preview(BrowserRowId rowId);
  Future<void> edit(BrowserRowId rowId);
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> selectedRows,
  );
}

/// Collection-backed editor and refresh capability used by the shared route.
abstract interface class CardBrowserNoteEditorController
    implements NoteEditorPort {
  Future<Int64> resolveNoteIdForRow(BrowserRowId rowId);
  Future<CardBrowserSnapshot> refresh();
}

abstract interface class CardBrowserNewNoteEditorController
    implements CardBrowserNoteEditorController, NewNoteEditorPort {}

/// Note-update-only collection undo exposed on source-matched browser surfaces.
abstract interface class CardBrowserNoteUpdateUndoController {
  bool get canUndoNoteUpdate;
  bool get noteUpdateUndoPending;
  Future<void> undoLastNoteUpdate();
}

/// Optional mode capability for controllers backed by a collection browser.
abstract interface class CardBrowserModeController {
  Future<CardBrowserSnapshot> updateMode(BrowserColumnMode mode);
}

/// Optional request capability for controllers that restore structured
/// history filters separately from the query text.
abstract interface class CardBrowserSearchRequestController {
  Future<CardBrowserSnapshot> searchRequest(BrowserSearchRequest request);
}

/// Optional persistent search-history capability.
abstract interface class CardBrowserSearchHistoryController {
  Future<List<BrowserSearchHistoryEntry>> loadSearchHistory();
  Future<BrowserSearchRequest> restoreSearchHistoryEntry(
    BrowserSearchHistoryEntry entry,
  );
  Future<void> removeSearchHistoryEntry(BrowserSearchHistoryEntry entry);
  Future<void> clearSearchHistory();
}

/// Optional collection projection that resolves and canonicalizes history
/// entries for display without changing their persisted identity.
typedef CardBrowserSearchHistoryDisplayItem = ({
  String? searchString,
  bool includesStructuredFilters,
});

abstract interface class CardBrowserSearchHistoryDisplayController {
  Future<List<CardBrowserSearchHistoryDisplayItem>>
  loadSearchHistoryDisplayItems(List<BrowserSearchHistoryEntry> entries);
}

/// Active-collection values that can be selected in the filter editor.
final class CardBrowserSearchFilterOptions {
  CardBrowserSearchFilterOptions({
    required List<BrowserDeckNameId> decks,
    required List<BrowserNoteTypeNameId> noteTypes,
    required List<String> tags,
  }) : decks = List.unmodifiable(decks),
       noteTypes = List.unmodifiable(noteTypes),
       tags = List.unmodifiable(tags);

  final List<BrowserDeckNameId> decks;
  final List<BrowserNoteTypeNameId> noteTypes;
  final List<String> tags;
}

/// Optional collection lookup used to populate the structured filter editor.
abstract interface class CardBrowserSearchFilterOptionsController {
  Future<CardBrowserSearchFilterOptions> loadSearchFilterOptions();
}

/// Responsive Card Browser UI shared by Flutter's mobile and desktop targets.
final class CardBrowserScreen extends StatefulWidget {
  const CardBrowserScreen({required this.controller, this.onClose, super.key});

  final CardBrowserController controller;
  final VoidCallback? onClose;

  @override
  State<CardBrowserScreen> createState() => _CardBrowserScreenState();
}

enum _BrowserLoadState { loading, loaded, searching, failed }

final class _CardBrowserScreenState extends State<CardBrowserScreen> {
  static const _wideLeadingWidth = 52.0;
  static const _wideColumnWidth = 180.0;
  static const _widePrimaryColumnWidth = 320.0;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final LinkedHashSet<BrowserRowId> _selectedRows = LinkedHashSet();
  final BrowserSearchHistoryDisplayModel _historyDisplay =
      BrowserSearchHistoryDisplayModel();
  List<BrowserSearchHistoryEntry> _searchHistory = const [];
  List<CardBrowserSearchHistoryDisplayItem> _searchHistoryDisplayItems =
      const [];
  BrowserSearchFilters _searchFilters = const BrowserSearchFilters();
  bool _searchFocused = false;
  CardBrowserSnapshot? _snapshot;
  _BrowserLoadState _loadState = _BrowserLoadState.loading;
  int _requestGeneration = 0;
  bool _failedDuringInitialLoad = false;
  bool _isMultiSelect = false;
  bool _noteUpdateUndoAvailable = false;
  bool _noteUpdateUndoPending = false;
  BrowserRowId? _lastSelectedRowId;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _load();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    setState(() => _searchFocused = _searchFocusNode.hasFocus);
    if (_searchFocused) _refreshSearchHistory();
  }

  @override
  void didUpdateWidget(covariant CardBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _searchController.clear();
      _searchHistory = const [];
      _searchFilters = const BrowserSearchFilters();
      _selectedRows.clear();
      _isMultiSelect = false;
      _lastSelectedRowId = null;
      _runAction(() => widget.controller.updateSelection(const []));
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loadState = _BrowserLoadState.loading;
      _failedDuringInitialLoad = false;
    });
    try {
      final snapshot = await widget.controller.load();
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _snapshot = snapshot;
        _loadState = _BrowserLoadState.loaded;
      });
      _refreshNoteUpdateUndoStatus();
      await _refreshSearchHistory();
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadState = _BrowserLoadState.failed;
        _failedDuringInitialLoad = true;
      });
      _refreshNoteUpdateUndoStatus();
    }
  }

  Future<void> _search(String query) async {
    await _searchRequest(
      BrowserSearchRequest(query: query, filters: _searchFilters),
    );
  }

  Future<void> _searchRequest(BrowserSearchRequest request) async {
    final generation = ++_requestGeneration;
    setState(() {
      _loadState = _BrowserLoadState.searching;
      _failedDuringInitialLoad = false;
    });
    try {
      final searchController = widget.controller;
      final snapshot = searchController is CardBrowserSearchRequestController
          ? await (searchController as CardBrowserSearchRequestController)
                .searchRequest(request)
          : await searchController.search(request.query);
      if (!mounted || generation != _requestGeneration) return;
      if (_lastSelectedRowId != null &&
          !snapshot.rows.any((row) => row.id == _lastSelectedRowId)) {
        _lastSelectedRowId = null;
      }
      setState(() {
        _snapshot = snapshot;
        _loadState = _BrowserLoadState.loaded;
      });
      _refreshNoteUpdateUndoStatus();
      await _refreshSearchHistory();
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadState = _BrowserLoadState.failed;
      });
      _refreshNoteUpdateUndoStatus();
      await _refreshSearchHistory();
    }
  }

  Future<void> _refreshSearchHistory() async {
    final controller = widget.controller;
    if (controller is! CardBrowserSearchHistoryController) return;
    try {
      final entries = await (controller as CardBrowserSearchHistoryController)
          .loadSearchHistory();
      var displayItems = [
        for (final entry in entries)
          (
            searchString: entry.query.isEmpty ? null : entry.query,
            includesStructuredFilters: false,
          ),
      ];
      if (controller is CardBrowserSearchHistoryDisplayController) {
        try {
          final projected =
              await (controller as CardBrowserSearchHistoryDisplayController)
                  .loadSearchHistoryDisplayItems(entries);
          if (projected.length == entries.length) displayItems = projected;
        } catch (_) {
          // History remains editable if a display-only projection fails.
        }
      }
      if (!mounted || controller != widget.controller) return;
      setState(() {
        _searchHistory = entries;
        _searchHistoryDisplayItems = displayItems;
      });
    } catch (error) {
      _showActionError(error);
    }
  }

  Future<void> _selectSearchHistoryEntry(
    BrowserSearchHistoryEntry entry, {
    required bool submit,
  }) async {
    final historyController = widget.controller;
    if (historyController is! CardBrowserSearchHistoryController) return;
    await _runAction(() async {
      final request =
          await (historyController as CardBrowserSearchHistoryController)
              .restoreSearchHistoryEntry(entry);
      if (!mounted || historyController != widget.controller) return;
      setState(() => _searchFilters = request.filters);
      _searchController.text = request.query.replaceAll('\n', ' ');
      _searchFocusNode.unfocus();
      if (submit) await _searchRequest(request);
    });
  }

  Future<void> _editSearchFilters() async {
    final current = _searchFilters;
    final filterController = widget.controller;
    if (filterController is! CardBrowserSearchFilterOptionsController) return;
    late final CardBrowserSearchFilterOptions options;
    try {
      options =
          await (filterController as CardBrowserSearchFilterOptionsController)
              .loadSearchFilterOptions();
    } catch (error) {
      _showActionError(error);
      return;
    }
    if (!mounted || filterController != widget.controller) return;
    final decksById = <String, BrowserDeckNameId>{
      for (final deck in options.decks) deck.id.toString(): deck,
      for (final deck in current.decks) deck.id.toString(): deck,
    };
    final noteTypesById = <String, BrowserNoteTypeNameId>{
      for (final noteType in options.noteTypes)
        noteType.id.toString(): noteType,
      for (final noteType in current.noteTypes)
        noteType.id.toString(): noteType,
    };
    final selectedDecks = List<BrowserDeckNameId>.of(current.decks);
    final selectedNoteTypes = List<BrowserNoteTypeNameId>.of(current.noteTypes);
    final selectedTags = current.tags.toSet();
    final selectedFlags = current.flags.toSet();
    final selectedCardStates = current.cardStateCodes.toSet();
    final updated = await showDialog<BrowserSearchFilters>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.browserFilters),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.browserFilterDecks),
                for (final deck in decksById.values)
                  CheckboxListTile(
                    dense: true,
                    key: ValueKey('browser-filter-deck-${deck.id}'),
                    contentPadding: EdgeInsets.zero,
                    value: selectedDecks.any(
                      (selected) =>
                          selected.id.toString() == deck.id.toString(),
                    ),
                    title: Text(deck.name),
                    onChanged: (value) => updateDialog(() {
                      selectedDecks.removeWhere(
                        (selected) => selected.id == deck.id,
                      );
                      if (value == true) selectedDecks.add(deck);
                    }),
                  ),
                Text(AppLocalizations.of(context)!.browserFilterNoteTypes),
                for (final noteType in noteTypesById.values)
                  CheckboxListTile(
                    dense: true,
                    key: ValueKey('browser-filter-note-type-${noteType.id}'),
                    contentPadding: EdgeInsets.zero,
                    value: selectedNoteTypes.any(
                      (selected) =>
                          selected.id.toString() == noteType.id.toString(),
                    ),
                    title: Text(noteType.name),
                    onChanged: (value) => updateDialog(() {
                      selectedNoteTypes.removeWhere(
                        (selected) =>
                            selected.id.toString() == noteType.id.toString(),
                      );
                      if (value == true) selectedNoteTypes.add(noteType);
                    }),
                  ),
                Text(AppLocalizations.of(context)!.browserFilterTags),
                for (final tag in {...options.tags, ...selectedTags})
                  CheckboxListTile(
                    dense: true,
                    key: ValueKey('browser-filter-tag-$tag'),
                    contentPadding: EdgeInsets.zero,
                    value: selectedTags.contains(tag),
                    title: Text(tag),
                    onChanged: (value) => updateDialog(() {
                      if (value == true) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    }),
                  ),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.browserFilterFlags),
                for (final option in const [
                  (0, 'None'),
                  (1, 'Red'),
                  (2, 'Orange'),
                  (3, 'Green'),
                  (4, 'Blue'),
                  (5, 'Pink'),
                  (6, 'Turquoise'),
                  (7, 'Purple'),
                ])
                  CheckboxListTile(
                    dense: true,
                    key: ValueKey('browser-filter-flag-${option.$1}'),
                    contentPadding: EdgeInsets.zero,
                    value: selectedFlags.contains(option.$1),
                    title: Text(option.$2),
                    onChanged: (value) => updateDialog(() {
                      if (value == true) {
                        selectedFlags.add(option.$1);
                      } else {
                        selectedFlags.remove(option.$1);
                      }
                    }),
                  ),
                Text(AppLocalizations.of(context)!.browserFilterCardStates),
                for (final option in const [
                  (0, 'New'),
                  (1, 'Learning'),
                  (2, 'Review'),
                  (3, 'Buried'),
                  (4, 'Suspended'),
                ])
                  CheckboxListTile(
                    dense: true,
                    key: ValueKey('browser-filter-card-state-${option.$1}'),
                    contentPadding: EdgeInsets.zero,
                    value: selectedCardStates.contains(option.$1),
                    title: Text(option.$2),
                    onChanged: (value) => updateDialog(() {
                      if (value == true) {
                        selectedCardStates.add(option.$1);
                      } else {
                        selectedCardStates.remove(option.$1);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              key: const ValueKey('browser-filter-apply'),
              onPressed: () {
                var filters = current;
                filters = (browserSetDecksFilter(
                  currentFilters: filters,
                  decks: selectedDecks,
                ) as BrowserFilterUpdateUser).state;
                filters = BrowserSearchFilters(
                  decks: filters.decks,
                  flags: filters.flags,
                  tags: filters.tags,
                  noteTypes: selectedNoteTypes,
                  cardStateCodes: filters.cardStateCodes,
                );
                filters = (browserSetTagsFilter(
                  currentFilters: filters,
                  tags: selectedTags.toList(),
                ) as BrowserFilterUpdateUser).state;
                filters = (browserSetFlagsFilter(
                  currentFilters: filters,
                  flags: [
                    for (var code = 0; code <= 7; code++)
                      if (selectedFlags.contains(code)) code,
                  ],
                ) as BrowserFilterUpdateUser).state;
                filters = (browserSetCardStateFilter(
                  currentFilters: filters,
                  cardStateCodes: [
                    for (var code = 0; code <= 4; code++)
                      if (selectedCardStates.contains(code)) code,
                  ],
                ) as BrowserFilterUpdateUser).state;
                Navigator.pop(dialogContext, filters);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _searchFilters = updated);
    await _searchRequest(
      BrowserSearchRequest(query: _searchController.text, filters: updated),
    );
  }

  Future<void> _removeSearchHistoryEntry(
    BrowserSearchHistoryEntry entry,
  ) async {
    final controller = widget.controller;
    if (controller is! CardBrowserSearchHistoryController) return;
    await _runAction(() async {
      await (controller as CardBrowserSearchHistoryController)
          .removeSearchHistoryEntry(entry);
      await _refreshSearchHistory();
    });
  }

  Future<void> _clearSearchHistory() async {
    final controller = widget.controller;
    if (controller is! CardBrowserSearchHistoryController) return;
    await _runAction(() async {
      await (controller as CardBrowserSearchHistoryController)
          .clearSearchHistory();
      await _refreshSearchHistory();
    });
  }

  String? _searchHistoryFilterSummary(BrowserSearchHistoryEntry entry) {
    final labels = AppLocalizations.of(context)!;
    final parts = <String>[];
    if (entry.deckIds.isNotEmpty) {
      parts.add(
        '${labels.browserFilterDecks}: ${entry.deckIds.map((id) => '#$id').join(', ')}',
      );
    }
    if (entry.flags.isNotEmpty) {
      const names = [
        'None',
        'Red',
        'Orange',
        'Green',
        'Blue',
        'Pink',
        'Turquoise',
        'Purple',
      ];
      parts.add(
        '${labels.browserFilterFlags}: ${entry.flags.map((code) => names[code]).join(', ')}',
      );
    }
    if (entry.tags.isNotEmpty) {
      parts.add('${labels.browserFilterTags}: ${entry.tags.join(', ')}');
    }
    if (entry.noteTypeIds.isNotEmpty) {
      parts.add(
        '${labels.browserFilterNoteTypes}: ${entry.noteTypeIds.map((id) => '#$id').join(', ')}',
      );
    }
    if (entry.cardStateCodes.isNotEmpty) {
      const names = ['New', 'Learning', 'Review', 'Buried', 'Suspended'];
      parts.add(
        '${labels.browserFilterCardStates}: ${entry.cardStateCodes.map((code) => names[code]).join(', ')}',
      );
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _buildSearchHistory() {
    if (!_searchFocused ||
        widget.controller is! CardBrowserSearchHistoryController ||
        _searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    final items = BrowserSearchHistoryLoaded([
      for (var index = 0; index < _searchHistory.length; index++)
        (
          entry: _searchHistory[index],
          searchString: _searchHistoryDisplayItems[index].searchString,
        ),
    ]);
    final projection = _historyDisplay.project(items);
    final visibleEntries = projection.items.entryToSearchString;
    return Card(
      key: const ValueKey('browser-search-history'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < visibleEntries.length; index++)
                ListTile(
                  dense: true,
                  key: ValueKey('browser-history-entry-$index'),
                  title: Text(
                    visibleEntries[index].searchString ??
                        (visibleEntries[index].entry.isSearchEmpty
                            ? AppLocalizations.of(context)!
                                  .browserHistoryAllCards
                            : AppLocalizations.of(context)!
                                  .browserHistoryFiltered),
                  ),
                  subtitle: switch (_searchHistoryDisplayItems[index]
                          .includesStructuredFilters
                      ? null
                      : _searchHistoryFilterSummary(
                          visibleEntries[index].entry,
                        )) {
                    final String summary => Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _ => null,
                  },
                  onTap: () => _selectSearchHistoryEntry(
                    visibleEntries[index].entry,
                    submit: true,
                  ),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        key: ValueKey('browser-history-edit-$index'),
                        tooltip: AppLocalizations.of(context)!
                            .browserHistoryEdit,
                        onPressed: () => _selectSearchHistoryEntry(
                          visibleEntries[index].entry,
                          submit: false,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        key: ValueKey('browser-history-remove-$index'),
                        tooltip: AppLocalizations.of(context)!
                            .browserHistoryRemove,
                        onPressed: () => _removeSearchHistoryEntry(
                          visibleEntries[index].entry,
                        ),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              if (_searchHistory.length > 5 || _searchHistory.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (projection.showHistoryToggle)
                      TextButton(
                        key: const ValueKey('browser-history-toggle'),
                        onPressed: () =>
                            setState(_historyDisplay.toggleHistoryExpanded),
                        child: Text(
                          _historyDisplay.isHistoryExpanded
                              ? AppLocalizations.of(context)!
                                    .browserHistoryShowLess
                              : AppLocalizations.of(context)!
                                    .browserHistoryShowMore,
                        ),
                      ),
                    TextButton(
                      key: const ValueKey('browser-history-clear'),
                      onPressed: _clearSearchHistory,
                      child: Text(
                        AppLocalizations.of(context)!.browserHistoryClear,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sort(BrowserSortType next) async {
    final generation = ++_requestGeneration;
    setState(() => _loadState = _BrowserLoadState.loaded);
    try {
      final snapshot = await widget.controller.updateSort(next);
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _snapshot = snapshot);
      _refreshNoteUpdateUndoStatus();
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      _showActionError(error);
      _refreshNoteUpdateUndoStatus();
    }
  }

  Future<void> _saveSearch() async {
    final query = browserSaveSearchPromptQuery(_searchController.text);
    if (query == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.browserSaveSearch),
        content: TextField(
          key: const ValueKey('browser-saved-search-name'),
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.browserSavedSearchName,
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            key: const ValueKey('browser-saved-search-confirm'),
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    nameController.dispose();
    if (!mounted || name == null) return;
    await _runAction(() async {
      final (added, _) = await widget.controller.addSavedSearch(
        BrowserSavedSearch(name: name, query: query),
      );
      if (!added && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.browserSavedSearchDuplicate,
            ),
          ),
        );
      }
    });
  }

  Future<void> _showSavedSearches() async {
    await _runAction(() async {
      final searches = await widget.controller.loadSavedSearches();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.browserSavedSearches),
          content: SizedBox(
            width: 480,
            child: searches.isEmpty
                ? Text(
                    AppLocalizations.of(dialogContext)!.browserNoSavedSearches,
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final search in searches)
                          ListTile(
                            key: ValueKey(
                              'browser-saved-search-${search.name}',
                            ),
                            title: Text(search.name),
                            subtitle: Text(search.query),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  key: ValueKey(
                                    'browser-saved-search-submit-${search.name}',
                                  ),
                                  tooltip: AppLocalizations.of(dialogContext)!
                                      .browserSubmitSavedSearch,
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _searchController.text = search.query;
                                    _search(search.query);
                                  },
                                  icon: const Icon(Icons.search),
                                ),
                                IconButton(
                                  key: ValueKey(
                                    'browser-saved-search-apply-${search.name}',
                                  ),
                                  tooltip: AppLocalizations.of(dialogContext)!
                                      .browserApplySavedSearch,
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _searchController.text = '${search.query} ';
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: ValueKey(
                                    'browser-saved-search-delete-${search.name}',
                                  ),
                                  tooltip: AppLocalizations.of(dialogContext)!
                                      .browserDelete,
                                  onPressed: () => _runAction(() async {
                                    await widget.controller.deleteSavedSearch(
                                      search.name,
                                    );
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    await _showSavedSearches();
                                  }),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(dialogContext)!.close),
            ),
          ],
        ),
      );
    });
  }

  void _toggleRow(BrowserRowId rowId) {
    final transition = toggleBrowserRowSelection(
      selectedRows: _selectedRows,
      selection: BrowserRowSelection(rowId: rowId, topOffset: 0),
      isInMultiSelectMode: _isMultiSelect,
    );
    _lastSelectedRowId = transition.lastSelectedRowId;
    _publishSelection(transition.selectedRows, transition.isInMultiSelectMode);
  }

  void _handleLongPress(BrowserRowId rowId) =>
      _handleRowSelection(rowId, isRightClick: false);

  void _handleRightClick(BrowserRowId rowId) =>
      _handleRowSelection(rowId, isRightClick: true);

  void _handleRowSelection(BrowserRowId rowId, {required bool isRightClick}) {
    final selection = BrowserRowSelection(rowId: rowId, topOffset: 0);
    final directive = isRightClick
        ? planBrowserRowRightClick(
            selection: selection,
            isInMultiSelectMode: _isMultiSelect,
            lastSelectedRowId: _lastSelectedRowId,
          )
        : planBrowserRowLongPress(
            selection: selection,
            isInMultiSelectMode: _isMultiSelect,
            lastSelectedRowId: _lastSelectedRowId,
          );
    switch (directive) {
      case BrowserRowToggleSelectionDirective(:final selection):
        _toggleRow(selection.rowId);
      case BrowserRowRangeSelectionDirective(
        :final startRowId,
        :final endRowId,
      ):
        final rowIds =
            _snapshot?.rows.map((row) => row.id).toList() ?? const [];
        final transition = planBrowserSelectRowsBetween(
          selectedRows: _selectedRows,
          rowIds: rowIds,
          startRowId: startRowId,
          endRowId: endRowId,
          isInMultiSelectMode: _isMultiSelect,
        );
        if (transition.changed) {
          _lastSelectedRowId = endRowId;
          _publishSelection(
            transition.selectedRows,
            transition.isInMultiSelectMode,
          );
        }
    }
  }

  void _publishSelection(List<BrowserRowId> rows, bool multiSelect) {
    setState(() {
      _selectedRows
        ..clear()
        ..addAll(rows);
      _isMultiSelect = multiSelect;
    });
    _runAction(() => widget.controller.updateSelection(rows));
  }

  void _activateRow(BrowserRowId rowId) {
    if (_isMultiSelect) {
      _toggleRow(rowId);
    } else {
      _editRow(rowId);
    }
  }

  void _previewSelected() {
    final controller = widget.controller;
    if (controller is CardBrowserPreviewController) {
      final selectedRows = List<BrowserRowId>.unmodifiable(_selectedRows);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CardBrowserPreviewScreen(
            controller: () => (controller as CardBrowserPreviewController)
                .loadPreview(selectedRows: selectedRows),
          ),
        ),
      );
      return;
    }
    final id = _selectedRows.firstOrNull;
    if (id != null) _runAction(() => controller.preview(id));
  }

  void _editSelected() {
    final id = _selectedRows.firstOrNull;
    if (id != null) _editRow(id);
  }

  Future<void> _editRow(BrowserRowId rowId) async {
    final controller = widget.controller;
    if (controller is! CardBrowserNoteEditorController) {
      await _runAction(() => controller.edit(rowId));
      return;
    }
    final editorController = controller as CardBrowserNoteEditorController;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorScreen(
          resolveNoteId: () => editorController.resolveNoteIdForRow(rowId),
          port: editorController,
        ),
      ),
    );
    if (!mounted) return;
    await _runAction(() async {
      final snapshot = await editorController.refresh();
      if (mounted) setState(() => _snapshot = snapshot);
    });
    _refreshNoteUpdateUndoStatus();
  }

  Future<void> _addNewNote() async {
    final controller = widget.controller;
    if (controller is! CardBrowserNewNoteEditorController) return;
    final newNoteController = controller as CardBrowserNewNoteEditorController;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            NoteEditorScreen.newNote(newNotePort: newNoteController),
      ),
    );
    if (!mounted) return;
    await _runAction(() async {
      final snapshot = await newNoteController.refresh();
      if (mounted) setState(() => _snapshot = snapshot);
    });
    _refreshNoteUpdateUndoStatus();
  }

  void _refreshNoteUpdateUndoStatus() {
    final controller = widget.controller;
    var available = false;
    if (controller is CardBrowserNoteUpdateUndoController) {
      try {
        available = (controller as CardBrowserNoteUpdateUndoController)
            .canUndoNoteUpdate;
      } catch (_) {
        available = false;
      }
    }
    if (!mounted) return;
    setState(() => _noteUpdateUndoAvailable = available);
  }

  bool get _undoActionAvailable {
    final controller = widget.controller;
    if (controller is! CardBrowserNoteUpdateUndoController ||
        _noteUpdateUndoPending) {
      return false;
    }
    final undoController = controller as CardBrowserNoteUpdateUndoController;
    try {
      return !undoController.noteUpdateUndoPending &&
          undoController.canUndoNoteUpdate;
    } catch (_) {
      return false;
    }
  }

  Future<void> _undoLastNoteUpdate() async {
    final controller = widget.controller;
    if (controller is! CardBrowserNoteUpdateUndoController) {
      _refreshNoteUpdateUndoStatus();
      return;
    }
    final undoController = controller as CardBrowserNoteUpdateUndoController;
    try {
      if (_noteUpdateUndoPending ||
          undoController.noteUpdateUndoPending ||
          !undoController.canUndoNoteUpdate) {
        _refreshNoteUpdateUndoStatus();
        return;
      }
    } catch (error) {
      _showActionError(error);
      _refreshNoteUpdateUndoStatus();
      return;
    }
    setState(() => _noteUpdateUndoPending = true);
    var undone = false;
    try {
      await undoController.undoLastNoteUpdate();
      undone = true;
    } catch (error) {
      _showActionError(error);
    }
    try {
      if (undone) {
        final editorController = widget.controller;
        if (editorController is CardBrowserNoteEditorController) {
          final snapshot =
              await (editorController as CardBrowserNoteEditorController)
                  .refresh();
          if (mounted) setState(() => _snapshot = snapshot);
        }
      }
    } catch (error) {
      _showActionError(error);
    } finally {
      if (mounted) {
        var available = false;
        try {
          available = undoController.canUndoNoteUpdate;
        } catch (_) {
          available = false;
        }
        setState(() {
          _noteUpdateUndoPending = false;
          _noteUpdateUndoAvailable = available;
        });
      }
    }
  }

  Future<void> _setMode(BrowserColumnMode mode) async {
    final controller = widget.controller;
    if (controller is! CardBrowserModeController || _snapshot?.mode == mode) {
      return;
    }
    final modeController = controller as CardBrowserModeController;
    final generation = ++_requestGeneration;
    try {
      final snapshot = await modeController.updateMode(mode);
      if (!mounted || generation != _requestGeneration) return;
      _selectedRows.clear();
      _lastSelectedRowId = null;
      _isMultiSelect = false;
      setState(() {
        _snapshot = snapshot;
        _loadState = _BrowserLoadState.loaded;
      });
      await _runAction(() => widget.controller.updateSelection(const []));
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      _showActionError(error);
      _refreshNoteUpdateUndoStatus();
    }
  }

  void _runBulkAction(CardBrowserBulkAction action) {
    _runAction(() async {
      await widget.controller.performBulkAction(
        action,
        List.unmodifiable(_selectedRows),
      );
      if (!mounted) return;
      if (action == CardBrowserBulkAction.delete) {
        _lastSelectedRowId = null;
        _publishSelection(const [], false);
      }
      await _search(_searchController.text);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _showActionError(error);
    } finally {
      _refreshNoteUpdateUndoStatus();
    }
  }

  void _showActionError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.browserActionFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        leading: widget.onClose == null
            ? null
            : BackButton(onPressed: widget.onClose),
        title: Text(s.cardBrowserTitle),
        actions: [
          if (widget.controller is CardBrowserNewNoteEditorController)
            IconButton(
              key: const ValueKey('browser-add-note'),
              tooltip: s.noteEditorAddTitle,
              onPressed: _addNewNote,
              icon: const Icon(Icons.add),
            ),
          if (_noteUpdateUndoAvailable)
            PopupMenuButton<String>(
              key: const ValueKey('browser-note-update-undo-menu'),
              tooltip: s.browserUndoNoteEdit,
              icon: const Icon(Icons.more_vert),
              onOpened: _refreshNoteUpdateUndoStatus,
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const ValueKey('browser-note-update-undo'),
                  value: 'undo',
                  enabled: _undoActionAvailable,
                  child: Text(s.browserUndoNoteEdit),
                ),
              ],
              onSelected: (_) => _undoLastNoteUpdate(),
            ),
          IconButton(
            key: const ValueKey('browser-manage-columns'),
            tooltip: 'Manage columns',
            onPressed: _manageColumns,
            icon: const Icon(Icons.view_column_outlined),
          ),
          if (_snapshot != null &&
              widget.controller is CardBrowserModeController)
            PopupMenuButton<BrowserColumnMode>(
              key: const ValueKey('browser-mode-menu'),
              tooltip: s.browserMode,
              icon: const Icon(Icons.view_list_outlined),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: BrowserColumnMode.cards,
                  child: Text(s.browserModeCards),
                ),
                PopupMenuItem(
                  value: BrowserColumnMode.notes,
                  child: Text(s.browserModeNotes),
                ),
              ],
              onSelected: _setMode,
            ),
          IconButton(
            key: const ValueKey('browser-save-search'),
            tooltip: s.browserSaveSearch,
            onPressed: _saveSearch,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          IconButton(
            key: const ValueKey('browser-saved-searches'),
            tooltip: s.browserSavedSearches,
            onPressed: _showSavedSearches,
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          if (snapshot != null)
            PopupMenuButton<BrowserColumn>(
              key: const ValueKey('browser-column-options-menu'),
              tooltip: 'Column options',
              icon: const Icon(Icons.more_horiz),
              itemBuilder: (context) => [
                for (final column in snapshot.columns)
                  PopupMenuItem(value: column.type, child: Text(column.label)),
              ],
              onSelected: _openColumnOptions,
            ),
          if (snapshot != null)
            PopupMenuButton<BrowserSortType>(
              key: const ValueKey('browser-sort-menu'),
              tooltip: s.browserSort,
              icon: const Icon(Icons.sort),
              itemBuilder: (context) {
                final options = buildBrowserSortOptions(
                  mode: snapshot.mode,
                  activeColumns: snapshot.columns.map((column) => column.type),
                  labels: {
                    for (final column in BrowserColumn.values)
                      column: _browserColumnSortLabel(s, column, snapshot.mode),
                    for (final column in snapshot.columns)
                      column.type: column.label,
                  },
                  selectedSort: snapshot.sortType,
                );
                final entries = <PopupMenuEntry<BrowserSortType>>[
                  PopupMenuItem(
                    value: const BrowserSortNoOrdering(),
                    child: Text(s.browserSortNoOrdering),
                  ),
                ];
                BrowserSortOptionSection? previousSection;
                for (final option in options) {
                  if (previousSection != option.section) {
                    entries.add(
                      PopupMenuItem<BrowserSortType>(
                        enabled: false,
                        child: Text(switch (option.section) {
                          BrowserSortOptionSection.active =>
                            s.browserSortActiveSection,
                          BrowserSortOptionSection.other =>
                            s.browserSortOtherSection,
                          BrowserSortOptionSection.unavailable =>
                            s.browserSortUnavailableSection,
                        }),
                      ),
                    );
                    previousSection = option.section;
                  }
                  entries.add(
                    PopupMenuItem(
                      value: BrowserSortCollectionOrdering(
                        key: option.column.key,
                        reverse:
                            snapshot.sortType
                                    is BrowserSortCollectionOrdering &&
                                (snapshot.sortType
                                            as BrowserSortCollectionOrdering)
                                        .key ==
                                    option.column.key
                            ? !(snapshot.sortType
                                      as BrowserSortCollectionOrdering)
                                  .reverse
                            : false,
                      ),
                      enabled: option.column.canSort(snapshot.mode),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.label),
                        subtitle: Text(_sortOptionSubtitle(s, option)),
                      ),
                    ),
                  );
                }
                return entries;
              },
              onSelected: (sortType) => _runAction(() => _sort(sortType)),
            ),
          if (_snapshot?.rows.isNotEmpty == true &&
              (widget.controller is CardBrowserPreviewController ||
                  _selectedRows.isNotEmpty))
            IconButton(
              key: const ValueKey('browser-preview'),
              tooltip: s.browserPreview,
              onPressed: _previewSelected,
              icon: const Icon(Icons.visibility_outlined),
            ),
          if (_selectedRows.isNotEmpty) ...[
            IconButton(
              key: const ValueKey('browser-edit'),
              tooltip: s.browserEdit,
              onPressed: _editSelected,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<CardBrowserBulkAction>(
              tooltip: s.browserBulkActions,
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const ValueKey('browser-bulk-suspend'),
                  value: CardBrowserBulkAction.suspend,
                  child: Text(s.browserSuspend),
                ),
                PopupMenuItem(
                  key: const ValueKey('browser-bulk-bury'),
                  value: CardBrowserBulkAction.bury,
                  child: Text(s.browserBury),
                ),
                PopupMenuItem(
                  key: const ValueKey('browser-bulk-delete'),
                  value: CardBrowserBulkAction.delete,
                  child: Text(s.browserDelete),
                ),
              ],
              onSelected: _runBulkAction,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              key: const ValueKey('browser-search'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: s.browserSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: s.search,
                  onPressed: () => _search(_searchController.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('browser-search-filters'),
              onPressed: _editSearchFilters,
              icon: const Icon(Icons.filter_list),
              label: Text(
                _searchFilters.tags.isEmpty &&
                        _searchFilters.decks.isEmpty &&
                        _searchFilters.noteTypes.isEmpty &&
                        _searchFilters.flags.isEmpty &&
                        _searchFilters.cardStateCodes.isEmpty
                    ? s.browserFilters
                    : '${s.browserFilters} (${_searchFilters.decks.length + _searchFilters.noteTypes.length + _searchFilters.tags.length + _searchFilters.flags.length + _searchFilters.cardStateCodes.length})',
              ),
            ),
          ),
          _buildSearchHistory(),
          if (_loadState == _BrowserLoadState.searching ||
              _loadState == _BrowserLoadState.loading)
            const LinearProgressIndicator(
              key: ValueKey('browser-search-progress'),
            ),
          Expanded(child: _buildResults(context, snapshot)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, CardBrowserSnapshot? snapshot) {
    final s = AppLocalizations.of(context)!;
    if (_loadState == _BrowserLoadState.failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.browserLoadFailed),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('browser-search-retry'),
              onPressed: _failedDuringInitialLoad
                  ? _load
                  : () => _search(_searchController.text),
              icon: const Icon(Icons.refresh),
              label: Text(s.tryAgain),
            ),
          ],
        ),
      );
    }
    if (snapshot == null || _loadState == _BrowserLoadState.loading) {
      return Center(child: Text(s.browserLoading));
    }
    if (snapshot.rows.isEmpty) {
      return Center(
        child: Text(
          snapshot.mode == BrowserColumnMode.cards
              ? s.browserNoCards
              : s.browserNoNotes,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return Semantics(
          key: ValueKey(
            isWide ? 'browser-layout-wide' : 'browser-layout-narrow',
          ),
          child: isWide
              ? _buildWideTable(snapshot, constraints.maxWidth)
              : _buildNarrowRows(snapshot),
        );
      },
    );
  }

  Widget _buildWideTable(CardBrowserSnapshot snapshot, double viewportWidth) {
    final s = AppLocalizations.of(context)!;
    final requiredWidth =
        _wideLeadingWidth +
        snapshot.columns.fold<double>(
          0,
          (width, column) => width + _wideColumnWidthFor(column),
        );
    return SingleChildScrollView(
      key: const ValueKey('browser-wide-horizontal-scroll'),
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: requiredWidth > viewportWidth ? requiredWidth : viewportWidth,
        child: Column(
          children: [
            _buildWideRow(
              leading: const SizedBox(width: _wideLeadingWidth),
              columns: snapshot.columns,
              isHeader: true,
              sortType: snapshot.sortType,
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: snapshot.rows.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = snapshot.rows[index];
                  final selected =
                      row.error == null && _selectedRows.contains(row.id);
                  return Semantics(
                    key: ValueKey('browser-row-${row.id.bigValue}'),
                    container: true,
                    button: true,
                    selected: selected,
                    label: _rowLabel(row, snapshot.columns),
                    child: InkWell(
                      onTap: () => _activateRow(row.id),
                      onLongPress: () => _handleLongPress(row.id),
                      onSecondaryTap: () => _handleRightClick(row.id),
                      child: Ink(
                        color: _rowBackground(row, Theme.of(context)),
                        child: _buildWideRow(
                          leading: SizedBox(
                            width: _wideLeadingWidth,
                            child: _isMultiSelect
                                ? Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleRow(row.id),
                                    semanticLabel: s.browserSelectRow(
                                      _rowTitle(row),
                                    ),
                                  )
                                : const Icon(Icons.drag_indicator, size: 18),
                          ),
                          columns: snapshot.columns,
                          row: row,
                          isHeader: false,
                          sortType: snapshot.sortType,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _wideColumnWidthFor(CardBrowserColumn column) =>
      column.type == BrowserColumn.question ||
          column.type == BrowserColumn.answer
      ? _widePrimaryColumnWidth
      : _wideColumnWidth;

  Widget _buildWideRow({
    required Widget leading,
    required List<CardBrowserColumn> columns,
    required bool isHeader,
    required BrowserSortType sortType,
    CardBrowserRow? row,
  }) => Row(
    children: [
      leading,
      for (final column in columns)
        SizedBox(
          width: _wideColumnWidthFor(column),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: isHeader
                ? _buildHeading(column, sortType)
                : Text(
                    row!.cells[column.type.key] ?? '',
                    style: TextStyle(
                      color: resolveCardBrowserRowForegroundColor(
                        row.color,
                        Theme.of(context),
                        deleted: row.error != null,
                      ),
                      decoration: row.error == null
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
    ],
  );

  Future<void> _openColumnOptions(BrowserColumn column) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text(column.key),
              subtitle: const Text('Column options'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove column'),
              enabled: (_snapshot?.columns.length ?? 0) > 1,
              onTap: () => Navigator.pop(context, 'remove'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Manage columns'),
              onTap: () => Navigator.pop(context, 'manage'),
            ),
          ],
        ),
      ),
    );
    if (action == 'manage') return _manageColumns();
    if (action == 'remove') {
      final columns =
          _snapshot?.columns.map((item) => item.type).toList() ?? [];
      columns.remove(column);
      await _runAction(() async {
        await widget.controller.saveColumns(columns);
        await _load();
      });
    }
  }

  Future<void> _manageColumns() async {
    final selected =
        _snapshot?.columns.map((column) => column.type).toList() ??
        [
          BrowserColumn.sortField,
          BrowserColumn.cardType,
          BrowserColumn.due,
          BrowserColumn.deck,
        ];
    final result = await showDialog<List<BrowserColumn>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage columns'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final column in [
                    ...selected,
                    ...BrowserColumn.values.where(
                      (column) => !selected.contains(column),
                    ),
                  ])
                    CheckboxListTile(
                      key: ValueKey('browser-column-${column.key}'),
                      dense: true,
                      value: selected.contains(column),
                      title: Text(column.key),
                      onChanged: (checked) => setDialogState(() {
                        if (checked == true && !selected.contains(column)) {
                          selected.add(column);
                        } else {
                          selected.remove(column);
                        }
                      }),
                      secondary: selected.contains(column)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Move up',
                                  onPressed: selected.indexOf(column) <= 0
                                      ? null
                                      : () => setDialogState(() {
                                          final index = selected.indexOf(
                                            column,
                                          );
                                          final value = selected.removeAt(
                                            index,
                                          );
                                          selected.insert(index - 1, value);
                                        }),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: 'Move down',
                                  onPressed:
                                      selected.indexOf(column) >=
                                          selected.length - 1
                                      ? null
                                      : () => setDialogState(() {
                                          final index = selected.indexOf(
                                            column,
                                          );
                                          final value = selected.removeAt(
                                            index,
                                          );
                                          selected.insert(index + 1, value);
                                        }),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                              ],
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, List.of(selected)),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await _runAction(() async {
      await widget.controller.saveColumns(result);
      await _load();
    });
  }

  Widget _buildHeading(CardBrowserColumn column, BrowserSortType sortType) {
    final active =
        sortType is BrowserSortCollectionOrdering &&
        sortType.key == column.type.key;
    return TextButton(
      key: ValueKey('browser-heading-${column.type.key}'),
      onPressed: () => _openColumnOptions(column.type),
      onLongPress: _manageColumns,
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(column.label, overflow: TextOverflow.ellipsis)),
          if (active)
            Icon(
              sortType.reverse ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildNarrowRows(CardBrowserSnapshot snapshot) => ListView.separated(
    itemCount: snapshot.rows.length,
    separatorBuilder: (context, index) => const SizedBox(height: 4),
    padding: const EdgeInsets.all(8),
    itemBuilder: (context, index) {
      final row = snapshot.rows[index];
      final selected = row.error == null && _selectedRows.contains(row.id);
      final foreground = resolveCardBrowserRowForegroundColor(
        row.color,
        Theme.of(context),
        deleted: row.error != null,
      );
      return Semantics(
        key: ValueKey('browser-row-${row.id.bigValue}'),
        container: true,
        button: true,
        selected: selected,
        label: _rowLabel(row, snapshot.columns),
        child: Card(
          color: _rowBackground(row, Theme.of(context)),
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _activateRow(row.id),
            onLongPress: () => _handleLongPress(row.id),
            onSecondaryTap: () => _handleRightClick(row.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isMultiSelect)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => _toggleRow(row.id),
                      semanticLabel: AppLocalizations.of(context)!
                          .browserSelectRow(_rowTitle(row)),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final column in snapshot.columns)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 92,
                                  child: Text(
                                    column.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: foreground),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    row.cells[column.type.key] ?? '',
                                    style: TextStyle(
                                      color: foreground,
                                      decoration: row.error == null
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                    maxLines:
                                        column.type == BrowserColumn.question ||
                                            column.type == BrowserColumn.answer
                                        ? 4
                                        : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey(
                                    'browser-column-options-${column.type.key}',
                                  ),
                                  tooltip: 'Column options: ${column.label}',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      _openColumnOptions(column.type),
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  String _rowTitle(CardBrowserRow row) {
    final columns = _snapshot?.columns ?? const <CardBrowserColumn>[];
    if (columns.isEmpty) return row.id.bigValue.toString();
    return row.cells[columns.first.type.key] ?? row.id.bigValue.toString();
  }

  Color _rowBackground(CardBrowserRow row, ThemeData theme) =>
      resolveCardBrowserRowColor(row.color, theme, deleted: row.error != null);

  String _rowLabel(CardBrowserRow row, List<CardBrowserColumn> columns) =>
      columns
          .map(
            (column) => '${column.label}: ${row.cells[column.type.key] ?? ''}',
          )
          .join(', ');
}

String _sortOptionSubtitle(AppLocalizations s, BrowserSortOption option) {
  if (!option.column.canSort(option.mode)) {
    return switch (option.unavailableReason) {
      BrowserColumnSortUnavailableReason.renderedTemplate =>
        s.browserSortUseField,
      BrowserColumnSortUnavailableReason.cardsModeOnly =>
        s.browserSortCardsOnly,
      BrowserColumnSortUnavailableReason.unsupported || null => '',
    };
  }
  return switch (option.selectedExplanation) {
    BrowserSortExplanation.textAscending => s.browserSortTextAscending,
    BrowserSortExplanation.textDescending => s.browserSortTextDescending,
    BrowserSortExplanation.numericAscending => s.browserSortNumericAscending,
    BrowserSortExplanation.numericDescending => s.browserSortNumericDescending,
    BrowserSortExplanation.dateAscending => s.browserSortDateAscending,
    BrowserSortExplanation.dateDescending => s.browserSortDateDescending,
    null => '',
  };
}

String _browserColumnSortLabel(
  AppLocalizations s,
  BrowserColumn column,
  BrowserColumnMode mode,
) => switch (column) {
  BrowserColumn.question => 'Question',
  BrowserColumn.answer => 'Answer',
  BrowserColumn.sortField => 'Sort field',
  BrowserColumn.deck => 'Deck',
  BrowserColumn.tags => 'Tags',
  BrowserColumn.cardType when mode == BrowserColumnMode.notes => 'Cards',
  BrowserColumn.cardType => 'Card type',
  BrowserColumn.noteType => 'Note type',
  BrowserColumn.due => s.browserColumnDue,
  BrowserColumn.ease =>
    mode == BrowserColumnMode.notes
        ? s.browserColumnAverageEase
        : s.browserColumnEase,
  BrowserColumn.changed => s.browserColumnCardModified,
  BrowserColumn.created => s.browserColumnCreated,
  BrowserColumn.edited => s.browserColumnNoteModified,
  BrowserColumn.interval =>
    mode == BrowserColumnMode.notes
        ? s.browserColumnAverageInterval
        : s.browserColumnInterval,
  BrowserColumn.lapses => s.browserColumnLapses,
  BrowserColumn.reviews => s.browserColumnReviews,
  BrowserColumn.fsrsDifficulty => s.browserColumnFsrsDifficulty,
  BrowserColumn.fsrsRetrievability => s.browserColumnFsrsRetrievability,
  BrowserColumn.fsrsStability => s.browserColumnFsrsStability,
  BrowserColumn.originalPosition => s.browserColumnOriginalPosition,
};
