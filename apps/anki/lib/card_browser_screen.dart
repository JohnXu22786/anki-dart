/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

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
  CardBrowserRow({required this.id, required Map<String, String> cells})
    : cells = Map.unmodifiable(cells);

  final BrowserRowId id;
  final Map<String, String> cells;
}

/// The immutable data shown by one completed Card Browser request.
final class CardBrowserSnapshot {
  CardBrowserSnapshot({
    required List<CardBrowserColumn> columns,
    required List<CardBrowserRow> rows,
    this.sortType = const BrowserSortNoOrdering(),
  }) : columns = List.unmodifiable(columns),
       rows = List.unmodifiable(rows);

  final List<CardBrowserColumn> columns;
  final List<CardBrowserRow> rows;
  final BrowserSortType sortType;
}

enum CardBrowserBulkAction { suspend, bury, delete }

/// Backend and navigation boundary for the cross-platform Card Browser.
///
/// Implementations execute query/search, collection IO, sort persistence,
/// selection actions, preview, and editor navigation outside the widget.
abstract interface class CardBrowserController {
  Future<CardBrowserSnapshot> load();
  Future<CardBrowserSnapshot> search(String query);
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType);
  Future<void> openColumnOptions(BrowserColumn column);
  Future<void> manageColumns();
  Future<void> updateSelection(List<BrowserRowId> selectedRows);
  Future<void> preview(BrowserRowId rowId);
  Future<void> edit(BrowserRowId rowId);
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> selectedRows,
  );
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
  final _searchController = TextEditingController();
  final LinkedHashSet<BrowserRowId> _selectedRows = LinkedHashSet();
  CardBrowserSnapshot? _snapshot;
  _BrowserLoadState _loadState = _BrowserLoadState.loading;
  int _requestGeneration = 0;
  bool _failedDuringInitialLoad = false;
  bool _isMultiSelect = false;
  BrowserRowId? _lastSelectedRowId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CardBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadState = _BrowserLoadState.failed;
        _failedDuringInitialLoad = true;
      });
    }
  }

  Future<void> _search(String query) async {
    final generation = ++_requestGeneration;
    setState(() {
      _loadState = _BrowserLoadState.searching;
      _failedDuringInitialLoad = false;
    });
    try {
      final snapshot = await widget.controller.search(query);
      if (!mounted || generation != _requestGeneration) return;
      if (_lastSelectedRowId != null &&
          !snapshot.rows.any((row) => row.id == _lastSelectedRowId)) {
        _lastSelectedRowId = null;
      }
      setState(() {
        _snapshot = snapshot;
        _loadState = _BrowserLoadState.loaded;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadState = _BrowserLoadState.failed;
      });
    }
  }

  Future<void> _sort(BrowserSortType next) async {
    final generation = ++_requestGeneration;
    setState(() => _loadState = _BrowserLoadState.loaded);
    try {
      final snapshot = await widget.controller.updateSort(next);
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _snapshot = snapshot);
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      _showActionError(error);
    }
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
      _runAction(() => widget.controller.edit(rowId));
    }
  }

  void _previewSelected() {
    final id = _selectedRows.firstOrNull;
    if (id != null) _runAction(() => widget.controller.preview(id));
  }

  void _editSelected() {
    final id = _selectedRows.firstOrNull;
    if (id != null) _runAction(() => widget.controller.edit(id));
  }

  void _runBulkAction(CardBrowserBulkAction action) {
    _runAction(
      () => widget.controller.performBulkAction(
        action,
        List.unmodifiable(_selectedRows),
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _showActionError(error);
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
          if (snapshot != null && snapshot.columns.isNotEmpty)
            PopupMenuButton<BrowserSortType>(
              key: const ValueKey('browser-sort-menu'),
              tooltip: s.browserSort,
              icon: const Icon(Icons.sort),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: const BrowserSortNoOrdering(),
                  child: Text(s.browserSortNoOrdering),
                ),
                for (final column in snapshot.columns)
                  PopupMenuItem(
                    value: BrowserSortCollectionOrdering(
                      key: column.type.key,
                      reverse:
                          snapshot.sortType is BrowserSortCollectionOrdering &&
                              (snapshot.sortType
                                          as BrowserSortCollectionOrdering)
                                      .key ==
                                  column.type.key
                          ? !(snapshot.sortType
                                    as BrowserSortCollectionOrdering)
                                .reverse
                          : false,
                    ),
                    child: Text('${s.browserSort}: ${column.label}'),
                  ),
              ],
              onSelected: (sortType) => _runAction(() => _sort(sortType)),
            ),
          if (_selectedRows.isNotEmpty) ...[
            IconButton(
              key: const ValueKey('browser-preview'),
              tooltip: s.browserPreview,
              onPressed: _previewSelected,
              icon: const Icon(Icons.visibility_outlined),
            ),
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
      return Center(child: Text(s.browserNoCards));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return Semantics(
          key: ValueKey(
            isWide ? 'browser-layout-wide' : 'browser-layout-narrow',
          ),
          child: isWide
              ? _buildWideTable(snapshot)
              : _buildNarrowRows(snapshot),
        );
      },
    );
  }

  Widget _buildWideTable(CardBrowserSnapshot snapshot) {
    final s = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildWideRow(
          leading: const SizedBox(width: 52),
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
              final selected = _selectedRows.contains(row.id);
              return Semantics(
                key: ValueKey('browser-row-${row.id.value}'),
                container: true,
                button: true,
                selected: selected,
                label: _rowLabel(row, snapshot.columns),
                child: InkWell(
                  onTap: () => _activateRow(row.id),
                  onLongPress: () => _handleLongPress(row.id),
                  onSecondaryTap: () => _handleRightClick(row.id),
                  child: _buildWideRow(
                    leading: SizedBox(
                      width: 52,
                      child: _isMultiSelect
                          ? Checkbox(
                              value: selected,
                              onChanged: (_) => _toggleRow(row.id),
                              semanticLabel: s.browserSelectRow(_rowTitle(row)),
                            )
                          : const Icon(Icons.drag_indicator, size: 18),
                    ),
                    columns: snapshot.columns,
                    row: row,
                    isHeader: false,
                    sortType: snapshot.sortType,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
        Expanded(
          flex:
              column.type == BrowserColumn.question ||
                  column.type == BrowserColumn.answer
              ? 3
              : 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: isHeader
                ? _buildHeading(column, sortType)
                : Text(
                    row!.cells[column.type.key] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
    ],
  );

  Widget _buildHeading(CardBrowserColumn column, BrowserSortType sortType) {
    final active =
        sortType is BrowserSortCollectionOrdering &&
        sortType.key == column.type.key;
    return TextButton(
      key: ValueKey('browser-heading-${column.type.key}'),
      onPressed: () =>
          _runAction(() => widget.controller.openColumnOptions(column.type)),
      onLongPress: () => _runAction(widget.controller.manageColumns),
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
      final selected = _selectedRows.contains(row.id);
      return Semantics(
        key: ValueKey('browser-row-${row.id.value}'),
        container: true,
        button: true,
        selected: selected,
        label: _rowLabel(row, snapshot.columns),
        child: Card(
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
                                        .labelMedium,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    row.cells[column.type.key] ?? '',
                                    maxLines:
                                        column.type == BrowserColumn.question ||
                                            column.type == BrowserColumn.answer
                                        ? 4
                                        : 2,
                                    overflow: TextOverflow.ellipsis,
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
    if (columns.isEmpty) return row.id.value.toString();
    return row.cells[columns.first.type.key] ?? row.id.value.toString();
  }

  String _rowLabel(CardBrowserRow row, List<CardBrowserColumn> columns) =>
      columns
          .map(
            (column) => '${column.label}: ${row.cells[column.type.key] ?? ''}',
          )
          .join(', ');
}
