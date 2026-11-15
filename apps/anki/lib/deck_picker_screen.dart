/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/deck_picker.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// Deck tree and due counts projected by the collection host for display.
final class DeckPickerDeck {
  const DeckPickerDeck({
    required this.id,
    required this.name,
    this.newCount = 0,
    this.learningCount = 0,
    this.reviewCount = 0,
    this.children = const [],
    this.filtered = false,
    this.collapsed = false,
    this.hasBuried = false,
  });
  final int id;
  final String name;
  final int newCount, learningCount, reviewCount;
  final List<DeckPickerDeck> children;
  final bool filtered, hasBuried, collapsed;
}

enum DeckPickerAction {
  addCard,
  browseCards,
  rebuildFilteredDeck,
  emptyFilteredDeck,
  renameDeck,
  createSubdeck,
  deckOptions,
  customStudy,
  exportDeck,
  unbury,
  createShortcut,
  editDescription,
  scheduleReminders,
  deleteDeck,
}

/// Values entered in filtered-deck options; query semantics belong to the host.
final class FilteredDeckRequest {
  const FilteredDeckRequest({
    required this.name,
    required this.search1,
    required this.limit1,
    required this.order1,
    required this.search2,
    required this.limit2,
    required this.order2,
    required this.secondFilterEnabled,
    required this.shouldReschedule,
    required this.delayAgain,
    required this.delayHard,
    required this.delayGood,
    required this.allowEmpty,
  });
  final String name,
      search1,
      limit1,
      search2,
      limit2,
      delayAgain,
      delayHard,
      delayGood;
  final int order1, order2;
  final bool secondFilterEnabled, shouldReschedule, allowEmpty;
}

/// A localized card-order choice paired with its backend enum number.
final class FilteredDeckOrderOption {
  const FilteredDeckOrderOption({
    required this.orderNumber,
    required this.label,
  });
  final int orderNumber;
  final String label;
}

/// Collection and navigation boundary. Implementations own persistence and Anki logic.
abstract interface class DeckPickerRepository {
  int? get currentDeckId;
  bool get scheduleRemindersEnabled;
  FilteredDeckOptions get newFilteredDeckOptions;
  List<FilteredDeckOrderOption> get filteredDeckOrderOptions;
  Future<List<DeckPickerDeck>> loadDecks();
  Future<void> selectDeck(int deckId);
  Future<void> study(int deckId);
  Future<void> toggleDeckExpand(int deckId);
  Future<void> performAction(DeckPickerAction action, int deckId);
  Future<void> createDeck(String name);
  Future<void> createSharedDeck();
  Future<void> buildFilteredDeck(FilteredDeckRequest request);
}

/// Explicit placeholder while a platform/backend collection service is not connected.
final class UnavailableDeckPickerRepository implements DeckPickerRepository {
  const UnavailableDeckPickerRepository();
  @override
  int? get currentDeckId => null;
  @override
  bool get scheduleRemindersEnabled => false;
  @override
  FilteredDeckOptions get newFilteredDeckOptions => const FilteredDeckOptions();
  @override
  List<FilteredDeckOrderOption> get filteredDeckOrderOptions => const [];
  Future<void> _unavailable() =>
      Future.error(UnsupportedError('Deck repository is not configured.'));
  @override
  Future<List<DeckPickerDeck>> loadDecks() =>
      Future.error(UnsupportedError('Deck repository is not configured.'));
  @override
  Future<void> selectDeck(int deckId) => _unavailable();
  @override
  Future<void> study(int deckId) => _unavailable();
  @override
  Future<void> toggleDeckExpand(int deckId) => _unavailable();
  @override
  Future<void> performAction(DeckPickerAction action, int deckId) =>
      _unavailable();
  @override
  Future<void> createDeck(String name) => _unavailable();
  @override
  Future<void> createSharedDeck() => _unavailable();
  @override
  Future<void> buildFilteredDeck(FilteredDeckRequest request) => _unavailable();
}

final class DeckPickerScreen extends StatefulWidget {
  const DeckPickerScreen({required this.repository, this.onClose, super.key});
  final DeckPickerRepository repository;
  final VoidCallback? onClose;
  @override
  State<DeckPickerScreen> createState() => _DeckPickerScreenState();
}

final class _DeckPickerScreenState extends State<DeckPickerScreen> {
  late Future<List<DeckPickerDeck>> _load;
  final _filterController = TextEditingController();
  int? _selectedId;
  String _filter = '';
  bool _showFilter = false, _showAddActions = false;
  bool _hasSearchableDeckList = false;
  int _loadGeneration = 0;
  int _selectionGeneration = 0;
  Future<void> _selectionTail = Future<void>.value();
  List<DeckPickerDeck> _loadedDecks = const [];
  @override
  void initState() {
    super.initState();
    _selectedId = widget.repository.currentDeckId;
    _load = _requestDecks();
  }

  @override
  void didUpdateWidget(covariant DeckPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _selectionGeneration++;
      _selectionTail = Future<void>.value();
      _selectedId = widget.repository.currentDeckId;
      _load = _requestDecks();
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _filterController.clear();
    setState(() => _filter = '');
  }

  void _toggleSearch() => setState(() {
    _showFilter = !_showFilter;
    if (!_showFilter) {
      _filterController.clear();
      _filter = '';
    }
  });

  Future<List<DeckPickerDeck>> _requestDecks() {
    final generation = ++_loadGeneration;
    final future = Future.sync(widget.repository.loadDecks);
    future.then(
      (decks) {
        if (mounted && generation == _loadGeneration) {
          setState(() {
            _loadedDecks = decks;
            _hasSearchableDeckList = _countDecks(decks) >= 10;
            final hostSelectedId = widget.repository.currentDeckId;
            _selectedId =
                hostSelectedId != null && _containsDeckId(decks, hostSelectedId)
                ? hostSelectedId
                : null;
          });
        }
      },
      onError: (Object _) {
        if (mounted && generation == _loadGeneration) {
          setState(() => _hasSearchableDeckList = false);
        }
      },
    );
    return future;
  }

  void _reload() => setState(() {
    _load = _requestDecks();
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: widget.onClose == null
            ? null
            : BackButton(onPressed: widget.onClose),
        title: _showFilter
            ? TextField(
                autofocus: true,
                controller: _filterController,
                decoration: InputDecoration(
                  hintText: s.searchDecks,
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    tooltip: s.clearSearch,
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onChanged: (v) => setState(() => _filter = v),
              )
            : Text(s.deckPickerTitle),
        actions: [
          if (_hasSearchableDeckList || _showFilter)
            IconButton(
              key: const ValueKey('deck-picker-search'),
              tooltip: _showFilter ? s.closeSearch : s.searchDecks,
              onPressed: _toggleSearch,
              icon: Icon(_showFilter ? Icons.close : Icons.search),
            ),
          IconButton(
            tooltip: s.refreshDecks,
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<DeckPickerDeck>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Semantics(
                label: s.loadingDecks,
                child: const CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            final unavailable = snapshot.error is UnsupportedError;
            return _MessageState(
              icon: unavailable
                  ? Icons.cloud_off_outlined
                  : Icons.error_outline,
              message: unavailable ? s.decksUnavailable : s.deckLoadFailed,
              actionLabel: unavailable ? null : s.tryAgain,
              onAction: unavailable ? null : _reload,
            );
          }
          final decks = snapshot.data ?? const <DeckPickerDeck>[];
          if (decks.isEmpty) {
            return _MessageState(
              icon: Icons.layers_outlined,
              message: s.noDecks,
            );
          }
          final deckIndex = <int, DeckPickerDeck>{};
          final tree = DeckNode.syntheticRoot(
            children: decks
                .map((deck) => _toDeckNode(deck, 0, deckIndex))
                .toList(growable: false),
          );
          final visible = tree.filterAndFlattenDisplay(
            DeckFilters.create(_filter),
            selectedDeckId: _selectedId ?? -1,
          );
          if (visible.isEmpty) {
            return _MessageState(
              icon: Icons.search_off,
              message: s.noDeckMatches,
            );
          }
          return LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 760;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 960 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          children: [
                            for (final row in visible)
                              _deckTile(row, deckIndex[row.did]!, s),
                          ],
                        ),
                      ),
                      if (_selectedId != null)
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              12,
                              wide ? 12 : 88,
                              12,
                            ),
                            child: SizedBox(
                              width: wide ? 320 : double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey('deck-study-selected'),
                                onPressed: () => _invoke(
                                  () => widget.repository.study(_selectedId!),
                                ),
                                icon: const Icon(Icons.play_arrow),
                                label: Text(s.study),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _showAddActions
          ? _addActions(s)
          : FloatingActionButton(
              key: const ValueKey('deck-picker-add'),
              heroTag: 'deck-picker-add',
              tooltip: s.add,
              onPressed: () => setState(() => _showAddActions = true),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _addActions(AppLocalizations s) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      _AddAction(
        label: s.addSharedDeck,
        onPressed: () => _invoke(widget.repository.createSharedDeck),
      ),
      const SizedBox(height: 8),
      _AddAction(label: s.createDeck, onPressed: _createDeck),
      const SizedBox(height: 8),
      _AddAction(label: s.createFilteredDeck, onPressed: _createFilteredDeck),
      const SizedBox(height: 8),
      FloatingActionButton.small(
        heroTag: 'deck-picker-add-close',
        tooltip: s.close,
        onPressed: () => setState(() => _showAddActions = false),
        child: const Icon(Icons.close),
      ),
    ],
  );

  Widget _deckTile(
    DisplayDeckNode row,
    DeckPickerDeck deck,
    AppLocalizations s,
  ) {
    final label = row.lastDeckNameComponent;
    final selected = _selectedId == deck.id;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        final heading = Row(
          children: [
            SizedBox(
              width: row.depth.clamp(0, 5).toDouble() * (compact ? 8.0 : 20.0),
            ),
            if (deck.children.isNotEmpty)
              SizedBox(
                width: 40,
                child: IconButton(
                  tooltip: deck.collapsed
                      ? s.expandDeck(label)
                      : s.collapseDeck(label),
                  onPressed: () => _invoke(
                    () => widget.repository.toggleDeckExpand(deck.id),
                  ),
                  icon: Icon(
                    deck.collapsed ? Icons.chevron_right : Icons.expand_more,
                  ),
                ),
              )
            else
              const SizedBox(width: 40),
            Expanded(
              child: InkWell(
                onTap: () => _selectDeck(deck.id),
                onSecondaryTapDown: (_) => _showDeckActions(deck, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        deck.children.isNotEmpty
                            ? Icons.folder_open
                            : Icons.style_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: selected ? FontWeight.bold : null,
                              ),
                        ),
                      ),
                      _CountBadge(
                        value: row.newCount,
                        color: Theme.of(context).colorScheme.tertiary,
                        label: s.newCards,
                      ),
                      _CountBadge(
                        value: row.lrnCount,
                        color: Theme.of(context).colorScheme.secondary,
                        label: s.learningCards,
                      ),
                      _CountBadge(
                        value: row.revCount,
                        color: Theme.of(context).colorScheme.primary,
                        label: s.reviewCards,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('deck-study-${deck.id}'),
              tooltip: s.studyDeck(label),
              onPressed: () => _invoke(() => widget.repository.study(deck.id)),
              icon: const Icon(Icons.play_arrow),
            ),
            IconButton(
              tooltip: s.deckActions(label),
              onPressed: () => _showDeckActions(deck, s),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        );
        return Card(
          color: selected
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          child: Semantics(
            key: ValueKey('deck-row-${deck.id}'),
            container: true,
            explicitChildNodes: true,
            label:
                '$label, ${s.deckCounts(row.newCount, row.lrnCount, row.revCount)}',
            selected: selected,
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: heading),
                      actions,
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _showDeckActions(DeckPickerDeck deck, AppLocalizations s) async {
    final action = await showModalBottomSheet<DeckPickerAction>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                deck.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final option in _actionsFor(deck))
              ListTile(
                leading: Icon(_actionIcon(option)),
                title: Text(_actionLabel(option, s)),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (action != null) {
      await _invoke(() => widget.repository.performAction(action, deck.id));
    }
  }

  List<DeckPickerAction> _actionsFor(DeckPickerDeck d) => [
    DeckPickerAction.addCard,
    DeckPickerAction.browseCards,
    if (d.filtered) ...[
      DeckPickerAction.rebuildFilteredDeck,
      DeckPickerAction.emptyFilteredDeck,
    ],
    DeckPickerAction.renameDeck,
    if (!d.filtered) DeckPickerAction.createSubdeck,
    DeckPickerAction.deckOptions,
    if (!d.filtered) DeckPickerAction.customStudy,
    DeckPickerAction.exportDeck,
    if (d.hasBuried) DeckPickerAction.unbury,
    DeckPickerAction.createShortcut,
    if (!d.filtered) DeckPickerAction.editDescription,
    if (widget.repository.scheduleRemindersEnabled)
      DeckPickerAction.scheduleReminders,
    DeckPickerAction.deleteDeck,
  ];
  String _actionLabel(DeckPickerAction a, AppLocalizations s) => switch (a) {
    DeckPickerAction.addCard => s.addCard,
    DeckPickerAction.browseCards => s.browseCards,
    DeckPickerAction.rebuildFilteredDeck => s.rebuildFilteredDeck,
    DeckPickerAction.emptyFilteredDeck => s.emptyFilteredDeck,
    DeckPickerAction.renameDeck => s.renameDeck,
    DeckPickerAction.createSubdeck => s.createSubdeck,
    DeckPickerAction.deckOptions => s.deckOptions,
    DeckPickerAction.customStudy => s.customStudy,
    DeckPickerAction.exportDeck => s.exportDeck,
    DeckPickerAction.unbury => s.unbury,
    DeckPickerAction.createShortcut => s.createShortcut,
    DeckPickerAction.editDescription => s.editDeckDescription,
    DeckPickerAction.scheduleReminders => s.scheduleReminders,
    DeckPickerAction.deleteDeck => s.deleteDeck,
  };
  IconData _actionIcon(DeckPickerAction a) => switch (a) {
    DeckPickerAction.addCard => Icons.note_add_outlined,
    DeckPickerAction.browseCards => Icons.view_list,
    DeckPickerAction.rebuildFilteredDeck => Icons.refresh,
    DeckPickerAction.emptyFilteredDeck => Icons.remove_circle_outline,
    DeckPickerAction.renameDeck => Icons.edit,
    DeckPickerAction.createSubdeck => Icons.create_new_folder_outlined,
    DeckPickerAction.deckOptions => Icons.tune,
    DeckPickerAction.customStudy => Icons.auto_awesome,
    DeckPickerAction.exportDeck => Icons.upload_outlined,
    DeckPickerAction.unbury => Icons.unarchive_outlined,
    DeckPickerAction.createShortcut => Icons.add_to_home_screen,
    DeckPickerAction.editDescription => Icons.description_outlined,
    DeckPickerAction.scheduleReminders => Icons.notifications_outlined,
    DeckPickerAction.deleteDeck => Icons.delete_outline,
  };

  Future<void> _createDeck() async {
    final s = AppLocalizations.of(context)!;
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.createDeck),
        content: TextField(
          key: const ValueKey('deck-name'),
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(labelText: s.deckName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctl.text),
            child: Text(s.create),
          ),
        ],
      ),
    );
    ctl.dispose();
    if (name != null) await _invoke(() => widget.repository.createDeck(name));
  }

  Future<void> _createFilteredDeck() async {
    if (_showAddActions) {
      setState(() => _showAddActions = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FilteredDeckOptionsScreen(
          initialOptions: widget.repository.newFilteredDeckOptions,
          orderOptions: widget.repository.filteredDeckOrderOptions,
          onBuild: widget.repository.buildFilteredDeck,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _invoke(Future<void> Function() action) async {
    setState(() => _showAddActions = false);
    try {
      await action();
      if (mounted) _reload();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckActionFailed),
          ),
        );
      }
    }
  }

  Future<void> _selectDeck(int deckId) async {
    final selectionGeneration = ++_selectionGeneration;
    final generation = _loadGeneration;
    final repository = widget.repository;
    final selection = _selectionTail.then((_) => repository.selectDeck(deckId));
    _selectionTail = selection.catchError((Object _) {});
    try {
      await selection;
      if (mounted && selectionGeneration == _selectionGeneration) {
        final selectedId = generation == _loadGeneration
            ? deckId
            : widget.repository.currentDeckId;
        if (selectedId != null && _containsDeckId(_loadedDecks, selectedId)) {
          setState(() => _selectedId = selectedId);
        }
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckActionFailed),
          ),
        );
      }
    }
  }
}

final class FilteredDeckOptionsScreen extends StatefulWidget {
  const FilteredDeckOptionsScreen({
    required this.initialOptions,
    required this.orderOptions,
    required this.onBuild,
    super.key,
  });
  final FilteredDeckOptions initialOptions;
  final List<FilteredDeckOrderOption> orderOptions;
  final Future<void> Function(FilteredDeckRequest) onBuild;
  @override
  State<FilteredDeckOptionsScreen> createState() =>
      _FilteredDeckOptionsScreenState();
}

final class _FilteredDeckOptionsScreenState
    extends State<FilteredDeckOptionsScreen> {
  late final TextEditingController _name,
      _search1,
      _limit1,
      _search2,
      _limit2,
      _again,
      _hard,
      _good;
  bool _second = false, _reschedule = true, _allowEmpty = true;
  int _order1 = 0, _order2 = 0;
  late final List<FilteredDeckOrderOption> _orderOptions;
  bool _building = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final options = widget.initialOptions;
    _name = TextEditingController(text: options.name);
    _search1 = TextEditingController(text: options.filter1State.search);
    _limit1 = TextEditingController(text: options.filter1State.limit);
    _search2 = TextEditingController(text: options.filter2State?.search ?? '');
    _limit2 = TextEditingController(text: options.filter2State?.limit ?? '100');
    _again = TextEditingController(text: options.delayAgain);
    _hard = TextEditingController(text: options.delayHard);
    _good = TextEditingController(text: options.delayGood);
    _second = options.isSecondFilterEnabled;
    _reschedule = options.shouldReschedule;
    _allowEmpty = options.allowEmpty;
    _order1 = options.filter1State.index;
    _order2 = options.filter2State?.index ?? 0;
    _orderOptions = widget.orderOptions;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _search1,
      _limit1,
      _search2,
      _limit2,
      _again,
      _hard,
      _good,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialOptions.title.isEmpty
              ? s.filteredDeckOptions
              : widget.initialOptions.title,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: c.maxWidth >= 760 ? 680 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('filtered-deck-name'),
                      controller: _name,
                      decoration: InputDecoration(labelText: s.deckName),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.filter,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('filtered-search-1'),
                      controller: _search1,
                      decoration: InputDecoration(labelText: s.search),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('filtered-limit-1'),
                      controller: _limit1,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.limitTo),
                    ),
                    if (_orderOptions.isNotEmpty)
                      DropdownButtonFormField<int>(
                        key: const ValueKey('filtered-order-1'),
                        initialValue: _validOrder(_order1),
                        decoration: InputDecoration(
                          labelText: s.cardsSelectedBy,
                        ),
                        items: [
                          for (final option in _orderOptions)
                            DropdownMenuItem(
                              value: option.orderNumber,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _order1 = value);
                        },
                      ),
                    SwitchListTile(
                      key: const ValueKey('filtered-second-filter-toggle'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.enableSecondFilter),
                      value: _second,
                      onChanged: (v) => setState(() => _second = v),
                    ),
                    if (_second) ...[
                      TextField(
                        key: const ValueKey('filtered-search-2'),
                        controller: _search2,
                        decoration: InputDecoration(labelText: s.secondSearch),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('filtered-limit-2'),
                        controller: _limit2,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: s.secondLimit),
                      ),
                      if (_orderOptions.isNotEmpty)
                        DropdownButtonFormField<int>(
                          key: const ValueKey('filtered-order-2'),
                          initialValue: _validOrder(_order2),
                          decoration: InputDecoration(
                            labelText: s.cardsSelectedBy,
                          ),
                          items: [
                            for (final option in _orderOptions)
                              DropdownMenuItem(
                                value: option.orderNumber,
                                child: Text(option.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _order2 = value);
                          },
                        ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      s.options,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SwitchListTile(
                      key: const ValueKey('filtered-reschedule'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.rescheduleCards),
                      value: _reschedule,
                      onChanged: (v) => setState(() => _reschedule = v),
                    ),
                    if (!_reschedule) ...[
                      TextField(
                        key: const ValueKey('filtered-delay-again'),
                        controller: _again,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: s.delayAgain),
                      ),
                      TextField(
                        key: const ValueKey('filtered-delay-hard'),
                        controller: _hard,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: s.delayHard),
                      ),
                      TextField(
                        key: const ValueKey('filtered-delay-good'),
                        controller: _good,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: s.delayGood),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.createEvenIfEmpty),
                      value: _allowEmpty,
                      onChanged: (v) => setState(() => _allowEmpty = v),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _building ? null : _build,
                      child: _building
                          ? const CircularProgressIndicator()
                          : Text(s.build),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _validOrder(int orderNumber) =>
      _orderOptions.any((option) => option.orderNumber == orderNumber)
      ? orderNumber
      : null;

  Future<void> _build() async {
    setState(() {
      _building = true;
      _error = null;
    });
    try {
      await widget.onBuild(
        FilteredDeckRequest(
          name: _name.text,
          search1: _search1.text,
          limit1: _limit1.text,
          order1: _order1,
          search2: _search2.text,
          limit2: _limit2.text,
          order2: _order2,
          secondFilterEnabled: _second,
          shouldReschedule: _reschedule,
          delayAgain: _again.text,
          delayHard: _hard.text,
          delayGood: _good.text,
          allowEmpty: _allowEmpty,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        setState(() {
          _building = false;
          _error = AppLocalizations.of(context)!.filteredDeckBuildFailed;
        });
      }
    }
  }
}

int _countDecks(Iterable<DeckPickerDeck> decks) =>
    decks.fold(0, (count, deck) => count + 1 + _countDecks(deck.children));

bool _containsDeckId(Iterable<DeckPickerDeck> decks, int id) =>
    decks.any((deck) => deck.id == id || _containsDeckId(deck.children, id));

final class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

final class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.value,
    required this.color,
    required this.label,
  });
  final int value;
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$value', textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}

final class _AddAction extends StatelessWidget {
  const _AddAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    heroTag: label,
    onPressed: onPressed,
    label: Text(label),
  );
}

DeckNode _toDeckNode(
  DeckPickerDeck deck,
  int depth,
  Map<int, DeckPickerDeck> deckIndex,
) {
  deckIndex[deck.id] = deck;
  return DeckNode(
    did: deck.id,
    fullDeckName: deck.name,
    depth: depth,
    collapsed: deck.collapsed,
    filtered: deck.filtered,
    newCount: deck.newCount,
    lrnCount: deck.learningCount,
    revCount: deck.reviewCount,
    children: [
      for (final child in deck.children)
        _toDeckNode(child, depth + 1, deckIndex),
    ],
  );
}
