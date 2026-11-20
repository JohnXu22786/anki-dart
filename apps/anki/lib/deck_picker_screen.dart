/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';

import 'package:anki_dart/deck_picker.dart';
import 'package:anki_dart/anki_dart.dart'
    show CustomStudyCardState, CustomStudySavedState;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'deck_picker_export_dialog.dart';
import 'note_editor_screen.dart';
import 'deck_description_editor.dart';
import 'deck_options_editor.dart';

/// Deck tree and due counts projected by the collection host for display.
final class DeckPickerDeck {
  const DeckPickerDeck({
    required this.id,
    required this.name,
    this.exactId,
    this.newCount = 0,
    this.learningCount = 0,
    this.reviewCount = 0,
    this.children = const [],
    this.filtered = false,
    this.collapsed = false,
    this.hasBuried = false,
  });
  final int id;

  /// Exact collection deck ID for backends that preserve 64-bit IDs on Web.
  final Int64? exactId;
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

enum _CustomStudyChoice {
  tags,
  reviewAhead,
  forgotten,
  previewNewCards,
  extendNew,
  extendReview,
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

/// Optional source route for opening the shared new-note editor from a deck.
abstract interface class DeckPickerNewNotePortProvider {
  Future<NewNoteEditorPort> selectDeckAndCreateNewNotePort(DeckPickerDeck deck);

  /// Opens the new-note route without an explicit deck override.
  ///
  /// The Deck Picker keyboard shortcut follows AnkiDroid's `deckId = null`
  /// behavior and lets the collection choose its current/default deck.
  Future<NewNoteEditorPort> createNewNotePortForCurrentDeck();
}

/// Optional source route that selects a deck without narrowing its 64-bit ID.
abstract interface class DeckPickerExactBrowseDeckProvider {
  Future<void> selectDeckForBrowse(DeckPickerDeck deck);
}

/// Platform-neutral export request route; the host owns export execution.
abstract interface class DeckPickerExportDeckProvider {
  Future<void> exportDeck(DeckPickerExportDeckRequest request);
}

/// Optional exact-ID route for Deck Picker rename, including validation used
/// while the rename dialog is open.
abstract interface class DeckPickerRenameProvider {
  bool isDeckNameAvailable(DeckPickerDeck deck, String name);
  Future<void> renameDeck(DeckPickerDeck deck, String name);
}

/// Collection-backed subdeck creation that retains the parent deck's exact ID.
abstract interface class DeckPickerCreateSubdeckProvider {
  bool isSubdeckNameAvailable(DeckPickerDeck parent, String name);
  Future<void> createSubdeck(DeckPickerDeck parent, String name);
}

/// Collection-backed delete route that preserves the deck's exact 64-bit ID.
abstract interface class DeckPickerDeleteProvider {
  Future<DeckPickerDeletionResult> deleteDeck(
    DeckPickerDeck deck, {
    required String defaultDeckName,
  });
}

/// Collection-backed Deck Picker unbury route preserving the exact deck ID.
abstract interface class DeckPickerUnburyProvider {
  Future<DeckPickerUnburyResult> unburyDeck(DeckPickerDeck deck);
}

/// Collection-backed filtered-deck empty route preserving the exact deck ID.
abstract interface class DeckPickerEmptyFilteredDeckProvider {
  Future<void> emptyFilteredDeck(DeckPickerDeck deck);
}

abstract interface class DeckPickerRebuildFilteredDeckProvider {
  Future<void> rebuildFilteredDeck(DeckPickerDeck deck);
}

abstract interface class DeckPickerCustomStudyProvider {
  Future<List<String>> customStudyTags(DeckPickerDeck deck);
  Future<void> createCustomStudy(
    DeckPickerDeck deck,
    CustomStudyTagsRequest request,
  );
}

abstract interface class DeckPickerReviewAheadProvider {
  Future<bool> hasReviewAheadCards(DeckPickerDeck deck, int days);
  Future<void> createReviewAhead(DeckPickerDeck deck, int days);
}

abstract interface class DeckPickerForgottenCardsProvider {
  Future<bool> hasForgottenCards(DeckPickerDeck deck, int days);
  Future<void> createForgottenCards(DeckPickerDeck deck, int days);
}

abstract interface class DeckPickerExtendLimitsProvider {
  Future<CustomStudyLimitDefaults> customStudyLimitDefaults(
    DeckPickerDeck deck,
  );
  Future<void> extendTodayLimits(
    DeckPickerDeck deck,
    CustomStudyLimitRequest request,
  );
}

enum CustomStudyLimitKind { newCards, reviewCards }

final class CustomStudyLimitRequest {
  const CustomStudyLimitRequest({required this.kind, required this.delta});
  final CustomStudyLimitKind kind;
  final int delta;
}

final class CustomStudyLimitDefaults {
  const CustomStudyLimitDefaults({
    required this.extendNew,
    required this.extendReview,
    required this.availableNew,
    required this.availableReview,
    required this.availableNewInChildren,
    required this.availableReviewInChildren,
  });
  final int extendNew,
      extendReview,
      availableNew,
      availableReview,
      availableNewInChildren,
      availableReviewInChildren;
}

abstract interface class DeckPickerPreviewNewCardsProvider {
  Future<void> createPreviewNewCards(DeckPickerDeck deck, int days);
}

final class CustomStudyTagsRequest {
  const CustomStudyTagsRequest({
    required this.state,
    required this.cardLimit,
    this.includedTags = const [],
    this.excludedTags = const [],
  });
  final CustomStudyCardState state;
  final int cardLimit;
  final List<String> includedTags, excludedTags;
}

/// Exact-ID route for loading and saving a normal deck's description.
abstract interface class DeckPickerDescriptionProvider {
  Future<DeckDescription> loadDescription(DeckPickerDeck deck);
  Future<void> saveDescription(
    DeckPickerDeck deck, {
    required String description,
    required bool markdownDescription,
  });
}

/// Collection-backed daily limit editing for normal decks and their presets.
abstract interface class DeckPickerDailyLimitsProvider {
  Future<DeckDailyLimits> loadDailyLimits(DeckPickerDeck deck);
  Future<void> saveDailyLimits(
    DeckPickerDeck deck, {
    required int newPerDay,
    required int reviewsPerDay,
  });
}

final class DeckPickerDeletionResult {
  const DeckPickerDeletionResult({
    required this.deckName,
    required this.cardsDeleted,
    this.collectionUndoGeneration = 0,
    this.persistenceWarning = false,
  });

  final String deckName;
  final int cardsDeleted;
  final int collectionUndoGeneration;
  final bool persistenceWarning;
}

final class DeckPickerUnburyResult {
  const DeckPickerUnburyResult({
    required this.deckName,
    required this.cardsUnburied,
    required this.collectionUndoGeneration,
    this.persistenceWarning = false,
  });

  final String deckName;
  final int cardsUnburied;
  final int collectionUndoGeneration;
  final bool persistenceWarning;
}

/// Undo and redo state exposed by collection-backed Deck Picker actions.
abstract interface class DeckPickerCollectionUndoProvider {
  bool get canUndoCollectionOperation;
  bool get canRedoCollectionOperation;
  int get collectionUndoGeneration;
  Future<void> undoLastCollectionOperation();
  Future<void> redoLastCollectionOperation();
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
  const DeckPickerScreen({
    required this.repository,
    this.onClose,
    this.onBrowseCards,
    super.key,
  });
  final DeckPickerRepository repository;
  final VoidCallback? onClose;
  final ValueChanged<Int64>? onBrowseCards;
  @override
  State<DeckPickerScreen> createState() => _DeckPickerScreenState();
}

final class _DeckPickerScreenState extends State<DeckPickerScreen>
    with RestorationMixin {
  late Future<List<DeckPickerDeck>> _load;
  final _filterController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int? _selectedId;
  final RestorableStringN _customStudyDeckId = RestorableStringN(null);
  final RestorableStringN _customStudyStage = RestorableStringN(null);
  final RestorableInt _customStudyCardStateIndex = RestorableInt(-1);
  bool _resumingCustomStudy = false;
  String _filter = '';
  bool _showFilter = false, _showAddActions = false;
  bool _hasSearchableDeckList = false;
  int _loadGeneration = 0;
  int _selectionGeneration = 0;
  Future<void> _selectionTail = Future<void>.value();
  List<DeckPickerDeck> _loadedDecks = const [];
  @override
  String? get restorationId => 'deck-picker';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_customStudyDeckId, 'custom-study-deck-id');
    registerForRestoration(_customStudyStage, 'custom-study-stage');
    registerForRestoration(
      _customStudyCardStateIndex,
      'custom-study-card-state-index',
    );
    if (_customStudyStage.value == 'tags') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resumeCustomStudyTags();
      });
    }
  }

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
    _searchFocusNode.dispose();
    _customStudyDeckId.dispose();
    _customStudyStage.dispose();
    _customStudyCardStateIndex.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _filterController.clear();
    setState(() => _filter = '');
  }

  void _toggleSearch() {
    setState(() {
      _showFilter = !_showFilter;
      if (!_showFilter) {
        _filterController.clear();
        _filter = '';
      }
    });
    if (_showFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showFilter) _searchFocusNode.requestFocus();
      });
    }
  }

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
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyUpEvent ||
            event.logicalKey != LogicalKeyboardKey.keyA ||
            _searchFocusNode.hasFocus) {
          return KeyEventResult.ignored;
        }
        if (widget.repository is DeckPickerNewNotePortProvider) {
          _addNoteForCurrentDeck();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: widget.onClose == null
              ? null
              : BackButton(onPressed: widget.onClose),
          title: _showFilter
              ? TextField(
                  autofocus: true,
                  controller: _filterController,
                  focusNode: _searchFocusNode,
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
            if (row.canCollapse)
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
      if (!mounted) return;
      if (action == DeckPickerAction.browseCards &&
          widget.onBrowseCards != null) {
        await _browseCards(deck);
      } else if (action == DeckPickerAction.exportDeck) {
        final repository = widget.repository;
        if (repository is DeckPickerExportDeckProvider) {
          final provider = repository as DeckPickerExportDeckProvider;
          await showDialog<void>(
            context: context,
            builder: (context) => DeckPickerExportDialog(
              decks: _loadedDecks,
              selectedDeckId: deck.exactId ?? Int64(deck.id),
              onExport: (request) =>
                  unawaited(_invoke(() => provider.exportDeck(request))),
            ),
          );
        } else {
          await _invoke(
            () => Future<void>.error(
              UnsupportedError('Deck export service is not configured.'),
            ),
          );
        }
      } else if (action == DeckPickerAction.addCard &&
          widget.repository is DeckPickerNewNotePortProvider) {
        await _addNote(deck);
      } else if (action == DeckPickerAction.renameDeck &&
          widget.repository is DeckPickerRenameProvider) {
        await _renameDeck(deck, s);
      } else if (action == DeckPickerAction.createSubdeck &&
          widget.repository is DeckPickerCreateSubdeckProvider) {
        await _createSubdeck(deck, s);
      } else if (action == DeckPickerAction.deleteDeck &&
          widget.repository is DeckPickerDeleteProvider) {
        await _deleteDeck(deck, s);
      } else if (action == DeckPickerAction.unbury &&
          widget.repository is DeckPickerUnburyProvider) {
        await _unburyDeck(deck, s);
      } else if (action == DeckPickerAction.emptyFilteredDeck &&
          widget.repository is DeckPickerEmptyFilteredDeckProvider) {
        final provider =
            widget.repository as DeckPickerEmptyFilteredDeckProvider;
        await _invoke(() => provider.emptyFilteredDeck(deck));
      } else if (action == DeckPickerAction.rebuildFilteredDeck &&
          widget.repository is DeckPickerRebuildFilteredDeckProvider) {
        final provider =
            widget.repository as DeckPickerRebuildFilteredDeckProvider;
        await _invoke(() => provider.rebuildFilteredDeck(deck));
      } else if (action == DeckPickerAction.customStudy &&
          widget.repository is DeckPickerCustomStudyProvider) {
        await _customStudy(deck);
      } else if (action == DeckPickerAction.editDescription &&
          widget.repository is DeckPickerDescriptionProvider) {
        await _editDescription(deck);
      } else if (action == DeckPickerAction.deckOptions &&
          !deck.filtered &&
          widget.repository is DeckPickerDailyLimitsProvider) {
        await _editDailyLimits(deck);
      } else {
        await _invoke(() => widget.repository.performAction(action, deck.id));
      }
    }
  }

  Future<void> _resumeCustomStudyTags() async {
    if (!mounted || _resumingCustomStudy || _customStudyStage.value != 'tags') {
      return;
    }
    _resumingCustomStudy = true;
    try {
      final savedDeckId = Int64.parseInt(
        CustomStudySavedState(
          selectedDeckId: _customStudyDeckId.value,
          selectedCardStateIndex: _customStudyCardStateIndex.value,
        ).requiredDeckId,
      );
      final decks = await _load;
      final deck = _findDeck(decks, savedDeckId);
      if (deck == null || !mounted) {
        _customStudyStage.value = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.deckActionFailed),
            ),
          );
        }
        return;
      }
      await _customStudy(deck, resumeTags: true);
    } on Object {
      _customStudyStage.value = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckActionFailed),
          ),
        );
      }
    } finally {
      _resumingCustomStudy = false;
    }
  }

  Future<void> _customStudy(
    DeckPickerDeck deck, {
    bool resumeTags = false,
  }) async {
    final provider = widget.repository as DeckPickerCustomStudyProvider;
    if (!resumeTags) {
      _customStudyDeckId.value = (deck.exactId ?? Int64(deck.id)).toString();
      _customStudyStage.value = 'choice';
    }
    final choice = resumeTags
        ? _CustomStudyChoice.tags
        : await showDialog<_CustomStudyChoice>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.customStudy),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.customStudyCardStateOrTag,
                    ),
                    onTap: () =>
                        Navigator.pop(context, _CustomStudyChoice.tags),
                  ),
                  if (widget.repository is DeckPickerReviewAheadProvider)
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.reviewAhead),
                      onTap: () => Navigator.pop(
                        context,
                        _CustomStudyChoice.reviewAhead,
                      ),
                    ),
                  if (widget.repository is DeckPickerForgottenCardsProvider)
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.forgottenCards),
                      onTap: () =>
                          Navigator.pop(context, _CustomStudyChoice.forgotten),
                    ),
                  if (widget.repository is DeckPickerPreviewNewCardsProvider)
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.previewNewCards,
                      ),
                      onTap: () => Navigator.pop(
                        context,
                        _CustomStudyChoice.previewNewCards,
                      ),
                    ),
                  if (widget.repository is DeckPickerExtendLimitsProvider) ...[
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.increaseTodaysNewLimit,
                      ),
                      onTap: () =>
                          Navigator.pop(context, _CustomStudyChoice.extendNew),
                    ),
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.increaseTodaysReviewLimit,
                      ),
                      onTap: () => Navigator.pop(
                        context,
                        _CustomStudyChoice.extendReview,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            ),
          );
    if (choice == null) {
      _customStudyStage.value = null;
      return;
    }
    if (choice == _CustomStudyChoice.reviewAhead) {
      _customStudyStage.value = null;
      await _reviewAhead(deck);
      return;
    }
    if (choice == _CustomStudyChoice.forgotten) {
      _customStudyStage.value = null;
      await _forgottenCards(deck);
      return;
    }
    if (choice == _CustomStudyChoice.previewNewCards) {
      _customStudyStage.value = null;
      await _previewNewCards(deck);
      return;
    }
    if (choice == _CustomStudyChoice.extendNew ||
        choice == _CustomStudyChoice.extendReview) {
      _customStudyStage.value = null;
      await _extendTodayLimits(deck, choice);
      return;
    }
    _customStudyStage.value = 'tags';
    late final List<String> tags;
    try {
      tags = await provider.customStudyTags(deck);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckActionFailed),
          ),
        );
      }
      _customStudyStage.value = null;
      return;
    }
    if (!mounted) return;
    final savedState = CustomStudySavedState(
      selectedDeckId: _customStudyDeckId.value,
      selectedCardStateIndex: _customStudyCardStateIndex.value,
    );
    final selectedDeckId = Int64.parseInt(savedState.requiredDeckId);
    if (selectedDeckId != (deck.exactId ?? Int64(deck.id))) {
      throw StateError('Restored Custom Study deck does not match its request');
    }
    final request = await showDialog<CustomStudyTagsRequest>(
      context: context,
      builder: (_) => _CustomStudyTagsDialog(
        tags: tags,
        initialSelectedIndex: _customStudyCardStateIndex.value,
        onSelectedIndexChanged: (index) {
          _customStudyCardStateIndex.value = index;
        },
      ),
    );
    _customStudyStage.value = null;
    if (request != null) {
      await _invoke(() async {
        await provider.createCustomStudy(deck, request);
        try {
          await SharedPreferencesAsync().setInt(
            'amountOfCards',
            request.cardLimit,
          );
        } on Object {
          // A saved default is optional; the created session already succeeded.
        }
      });
    }
  }

  Future<void> _reviewAhead(DeckPickerDeck deck) async {
    final provider = widget.repository as DeckPickerReviewAheadProvider;
    final saved = await SharedPreferencesAsync().getInt('aheadDays');
    if (!mounted) return;
    final days = await showDialog<int>(
      context: context,
      builder: (_) => _ReviewAheadDialog(
        initialDays: saved ?? 1,
        hasCards: (value) => provider.hasReviewAheadCards(deck, value),
      ),
    );
    if (days == null) return;
    await _invoke(() async {
      await provider.createReviewAhead(deck, days);
      try {
        await SharedPreferencesAsync().setInt('aheadDays', days);
      } on Object {
        // Saving a default is optional after the collection operation succeeds.
      }
    });
  }

  Future<void> _forgottenCards(DeckPickerDeck deck) async {
    final provider = widget.repository as DeckPickerForgottenCardsProvider;
    final saved = await SharedPreferencesAsync().getInt('forgottenDays');
    if (!mounted) return;
    final days = await showDialog<int>(
      context: context,
      builder: (_) => _ReviewAheadDialog(
        initialDays: saved ?? 1,
        hasCards: (value) => provider.hasForgottenCards(deck, value),
        maxDays: 0x7fffffff,
        title: AppLocalizations.of(context)!.forgottenCards,
        daysLabel: AppLocalizations.of(context)!.forgottenCardsDays,
      ),
    );
    if (days == null) return;
    await _invoke(() async {
      await provider.createForgottenCards(deck, days);
      try {
        await SharedPreferencesAsync().setInt('forgottenDays', days);
      } on Object {
        // Saving a default is optional after the collection operation succeeds.
      }
    });
  }

  Future<void> _previewNewCards(DeckPickerDeck deck) async {
    final provider = widget.repository as DeckPickerPreviewNewCardsProvider;
    final saved = await SharedPreferencesAsync().getInt('previewDays');
    if (!mounted) return;
    final days = await showDialog<int>(
      context: context,
      builder: (_) => _PreviewNewCardsDialog(
        initialDays: saved ?? 1,
        title: AppLocalizations.of(context)!.previewNewCards,
        daysLabel: AppLocalizations.of(context)!.previewNewCardsDays,
      ),
    );
    if (days == null) return;
    await _invoke(() async {
      await provider.createPreviewNewCards(deck, days);
      try {
        await SharedPreferencesAsync().setInt('previewDays', days);
      } on Object {
        // Saving a default is optional after the collection operation succeeds.
      }
    });
  }

  Future<void> _extendTodayLimits(
    DeckPickerDeck deck,
    _CustomStudyChoice choice,
  ) async {
    final provider = widget.repository as DeckPickerExtendLimitsProvider;
    final isNew = choice == _CustomStudyChoice.extendNew;
    try {
      final defaults = await provider.customStudyLimitDefaults(deck);
      if (!mounted) return;
      final value = await showDialog<int>(
        context: context,
        builder: (_) => _ExtendTodayLimitDialog(
          title: isNew
              ? AppLocalizations.of(context)!.increaseTodaysNewLimit
              : AppLocalizations.of(context)!.increaseTodaysReviewLimit,
          initialValue: isNew ? defaults.extendNew : defaults.extendReview,
          available: isNew ? defaults.availableNew : defaults.availableReview,
          availableInChildren: isNew
              ? defaults.availableNewInChildren
              : defaults.availableReviewInChildren,
          availableLabel: isNew
              ? AppLocalizations.of(context)!.availableNewCards
              : AppLocalizations.of(context)!.availableReviewCards,
        ),
      );
      if (value == null) return;
      await _invoke(
        () => provider.extendTodayLimits(
          deck,
          CustomStudyLimitRequest(
            kind: isNew
                ? CustomStudyLimitKind.newCards
                : CustomStudyLimitKind.reviewCards,
            delta: value,
          ),
        ),
        reloadOnError: true,
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _editDailyLimits(DeckPickerDeck deck) async {
    final provider = widget.repository as DeckPickerDailyLimitsProvider;
    try {
      final limits = await provider.loadDailyLimits(deck);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeckOptionsEditor(
          deckName: deck.name,
          initialNewPerDay: limits.newPerDay,
          initialReviewsPerDay: limits.reviewsPerDay,
          onSave: (newPerDay, reviewsPerDay) async {
            try {
              await provider.saveDailyLimits(
                deck,
                newPerDay: newPerDay,
                reviewsPerDay: reviewsPerDay,
              );
            } on Object {
              // Storage may commit before a platform flush fails.
              if (mounted) _reload();
              rethrow;
            }
          },
          onSaved: () {
            if (!mounted) return;
            _reload();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.deckOptionsSaved),
              ),
            );
          },
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _editDescription(DeckPickerDeck deck) async {
    final provider = widget.repository as DeckPickerDescriptionProvider;
    try {
      final initial = await provider.loadDescription(deck);
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeckDescriptionEditor(
          initial: initial,
          onSave: (description, markdown) => provider.saveDescription(
            deck,
            description: description,
            markdownDescription: markdown,
          ),
        ),
      );
      if (saved == true && mounted) {
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckDescriptionSaved),
          ),
        );
      }
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _unburyDeck(DeckPickerDeck deck, AppLocalizations s) async {
    final provider = widget.repository as DeckPickerUnburyProvider;
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(s.unburyingDeck)),
            ],
          ),
        ),
      ),
    );
    try {
      final result = await provider.unburyDeck(deck);
      if (navigator.canPop()) navigator.pop();
      await progress;
      if (!mounted) return;
      _reload();
      final message = result.persistenceWarning
          ? '${s.deckUnburiedResult(result.cardsUnburied, result.deckName)}\n${s.deckDeletionFlushWarning}'
          : s.deckUnburiedResult(result.cardsUnburied, result.deckName);
      final undoProvider = widget.repository;
      final undo = undoProvider is DeckPickerCollectionUndoProvider
          ? undoProvider as DeckPickerCollectionUndoProvider
          : null;
      if (undo != null &&
          result.cardsUnburied > 0 &&
          undo.canUndoCollectionOperation &&
          undo.collectionUndoGeneration == result.collectionUndoGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: s.undoDeckUnbury,
              onPressed: () =>
                  _undoDeckUnbury(undo, result.collectionUndoGeneration),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on Object {
      if (navigator.canPop()) navigator.pop();
      await progress;
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.deckActionFailed)));
    }
  }

  Future<void> _undoDeckUnbury(
    DeckPickerCollectionUndoProvider provider,
    int generation,
  ) async {
    if (!provider.canUndoCollectionOperation ||
        provider.collectionUndoGeneration != generation) {
      return;
    }
    try {
      await provider.undoLastCollectionOperation();
      if (!mounted) return;
      _reload();
      final redoGeneration = provider.collectionUndoGeneration;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deckUnburyUndone),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.redoDeckUnbury,
            onPressed: () => _redoDeckUnbury(provider, redoGeneration),
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _redoDeckUnbury(
    DeckPickerCollectionUndoProvider provider,
    int generation,
  ) async {
    if (!provider.canRedoCollectionOperation ||
        provider.collectionUndoGeneration != generation) {
      return;
    }
    try {
      await provider.redoLastCollectionOperation();
      if (!mounted) return;
      _reload();
      final undoGeneration = provider.collectionUndoGeneration;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deckUnburyRedone),
          action: provider.canUndoCollectionOperation
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.undoDeckUnbury,
                  onPressed: () => _undoDeckUnbury(provider, undoGeneration),
                )
              : null,
        ),
      );
    } on Object {
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _deleteDeck(DeckPickerDeck deck, AppLocalizations s) async {
    final provider = widget.repository as DeckPickerDeleteProvider;
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(s.deletingDeck)),
            ],
          ),
        ),
      ),
    );
    try {
      final result = await provider.deleteDeck(
        deck,
        defaultDeckName: s.collectionDefaultDeck,
      );
      if (navigator.canPop()) navigator.pop();
      await progress;
      if (!mounted) return;
      _reload();
      final message = result.persistenceWarning
          ? '${s.deckDeletionResult(result.cardsDeleted, result.deckName)}\n${s.deckDeletionFlushWarning}'
          : s.deckDeletionResult(result.cardsDeleted, result.deckName);
      final undoProvider = widget.repository;
      final undo = undoProvider is DeckPickerCollectionUndoProvider
          ? undoProvider as DeckPickerCollectionUndoProvider
          : null;
      if (undo != null &&
          undo.canUndoCollectionOperation &&
          undo.collectionUndoGeneration == result.collectionUndoGeneration) {
        final generation = result.collectionUndoGeneration;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: s.undoDeckDeletion,
              onPressed: () => _undoDeckDeletion(undo, generation),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on Object {
      if (navigator.canPop()) navigator.pop();
      await progress;
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.deckActionFailed)));
    }
  }

  Future<void> _undoDeckDeletion(
    DeckPickerCollectionUndoProvider provider,
    int generation,
  ) async {
    if (!provider.canUndoCollectionOperation ||
        provider.collectionUndoGeneration != generation) {
      return;
    }
    try {
      await provider.undoLastCollectionOperation();
      if (!mounted) return;
      _reload();
      final redoGeneration = provider.collectionUndoGeneration;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deckDeletionUndone),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.redoDeckDeletion,
            onPressed: () => _redoDeckDeletion(provider, redoGeneration),
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _redoDeckDeletion(
    DeckPickerCollectionUndoProvider provider,
    int generation,
  ) async {
    if (!provider.canRedoCollectionOperation ||
        provider.collectionUndoGeneration != generation) {
      return;
    }
    try {
      await provider.redoLastCollectionOperation();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deckDeletionRedone),
        ),
      );
    } on Object {
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _renameDeck(DeckPickerDeck deck, AppLocalizations s) async {
    final provider = widget.repository as DeckPickerRenameProvider;
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        var available = provider.isDeckNameAvailable(deck, deck.name);
        var value = deck.name;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(s.renameDeck),
            content: TextFormField(
              key: const ValueKey('rename-deck-name'),
              initialValue: value,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.newDeckName,
                errorText: value.trim().isEmpty || available
                    ? null
                    : s.deckNameExists,
              ),
              onChanged: (newValue) => setDialogState(() {
                value = newValue;
                available = provider.isDeckNameAvailable(deck, newValue);
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: value.trim().isEmpty || !available
                    ? null
                    : () => Navigator.pop(context, value),
                child: Text(s.rename),
              ),
            ],
          ),
        );
      },
    );
    if (name != null) {
      await _invoke(() => provider.renameDeck(deck, name), reloadOnError: true);
    }
  }

  Future<void> _createSubdeck(DeckPickerDeck parent, AppLocalizations s) async {
    final provider = widget.repository as DeckPickerCreateSubdeckProvider;
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        var available = provider.isSubdeckNameAvailable(parent, '');
        var value = '';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(s.createSubdeck),
            content: TextFormField(
              key: const ValueKey('subdeck-name'),
              initialValue: value,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.deckName,
                errorText:
                    value.isEmpty ||
                        value.replaceAll('"', '').isEmpty ||
                        available
                    ? null
                    : s.deckNameExists,
              ),
              onChanged: (newValue) => setDialogState(() {
                value = newValue;
                available = provider.isSubdeckNameAvailable(parent, newValue);
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: value.isEmpty || !available
                    ? null
                    : () => Navigator.pop(context, value),
                child: Text(s.create),
              ),
            ],
          ),
        );
      },
    );
    if (name != null) {
      await _invoke(
        () => provider.createSubdeck(parent, name),
        reloadOnError: true,
      );
    }
  }

  Future<void> _addNote(DeckPickerDeck deck) async {
    final repository = widget.repository;
    if (repository is! DeckPickerNewNotePortProvider) return;
    final notePortProvider = repository as DeckPickerNewNotePortProvider;
    try {
      // AnkiDroid's DeckPickerViewModel.addNote() calls decks.select() for
      // the context-menu deck before navigating to NoteEditorDestination.AddNote.
      final newNotePort = await notePortProvider.selectDeckAndCreateNewNotePort(
        deck,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => NoteEditorScreen.newNote(newNotePort: newNotePort),
        ),
      );
      if (!mounted) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _addNoteForCurrentDeck() async {
    final repository = widget.repository;
    if (repository is! DeckPickerNewNotePortProvider) return;
    final portProvider = repository as DeckPickerNewNotePortProvider;
    try {
      final newNotePort = await portProvider.createNewNotePortForCurrentDeck();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => NoteEditorScreen.newNote(newNotePort: newNotePort),
        ),
      );
      if (!mounted) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckActionFailed)),
      );
    }
  }

  Future<void> _browseCards(DeckPickerDeck deck) async {
    setState(() => _showAddActions = false);
    try {
      final repository = widget.repository;
      if (repository is DeckPickerExactBrowseDeckProvider) {
        final exactBrowser = repository as DeckPickerExactBrowseDeckProvider;
        await exactBrowser.selectDeckForBrowse(deck);
      } else {
        await repository.selectDeck(deck.id);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deckActionFailed),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    _reload();
    widget.onBrowseCards?.call(deck.exactId ?? Int64(deck.id));
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

  Future<void> _invoke(
    Future<void> Function() action, {
    bool reloadOnError = false,
  }) async {
    setState(() => _showAddActions = false);
    try {
      await action();
      if (mounted) _reload();
    } on Object {
      if (mounted) {
        if (reloadOnError) _reload();
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

DeckPickerDeck? _findDeck(Iterable<DeckPickerDeck> decks, Int64 exactId) {
  for (final deck in decks) {
    if ((deck.exactId ?? Int64(deck.id)) == exactId) return deck;
    final child = _findDeck(deck.children, exactId);
    if (child != null) return child;
  }
  return null;
}

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

final class _ExtendTodayLimitDialog extends StatefulWidget {
  const _ExtendTodayLimitDialog({
    required this.title,
    required this.initialValue,
    required this.available,
    required this.availableInChildren,
    required this.availableLabel,
  });
  final String title, availableLabel;
  final int initialValue, available, availableInChildren;
  @override
  State<_ExtendTodayLimitDialog> createState() =>
      _ExtendTodayLimitDialogState();
}

class _ExtendTodayLimitDialogState extends State<_ExtendTodayLimitDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue.toString(),
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.availableInChildren == 0
              ? '${widget.availableLabel}: ${widget.available}'
              : '${widget.availableLabel}: ${widget.available} (${widget.availableInChildren} ${AppLocalizations.of(context)!.inSubdecks})',
        ),
        TextField(
          key: const ValueKey('custom-study-limit-delta'),
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context)!.cancel),
      ),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, editingValue, child) {
          final parsed = int.tryParse(editingValue.text);
          final value =
              parsed != null && parsed >= -0x80000000 && parsed <= 0x7fffffff
              ? parsed
              : null;
          return TextButton(
            onPressed: value == null || value == 0
                ? null
                : () => Navigator.pop(context, value),
            child: child!,
          );
        },
        child: Text(AppLocalizations.of(context)!.ok),
      ),
    ],
  );
}

final class _ReviewAheadDialog extends StatefulWidget {
  const _ReviewAheadDialog({
    required this.initialDays,
    required this.hasCards,
    this.maxDays = 99999,
    this.title,
    this.daysLabel,
  });

  final int initialDays;
  final Future<bool> Function(int days) hasCards;
  final int maxDays;
  final String? title;
  final String? daysLabel;

  @override
  State<_ReviewAheadDialog> createState() => _ReviewAheadDialogState();
}

final class _PreviewNewCardsDialog extends StatefulWidget {
  const _PreviewNewCardsDialog({
    required this.initialDays,
    required this.title,
    required this.daysLabel,
  });

  final int initialDays;
  final String title;
  final String daysLabel;

  @override
  State<_PreviewNewCardsDialog> createState() => _PreviewNewCardsDialogState();
}

final class _PreviewNewCardsDialogState extends State<_PreviewNewCardsDialog> {
  late final TextEditingController days;
  bool _validInput = true;

  @override
  void initState() {
    super.initState();
    days = TextEditingController(
      text: widget.initialDays.clamp(1, 0x7fffffff).toString(),
    );
  }

  @override
  void dispose() {
    days.dispose();
    super.dispose();
  }

  void _validate(String text) {
    final value = int.tryParse(text);
    setState(
      () => _validInput = value != null && value > 0 && value <= 0x7fffffff,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: days,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        onChanged: _validate,
        decoration: InputDecoration(
          labelText: widget.daysLabel,
          suffixText: int.tryParse(days.text) == 1 ? s.day : s.days,
          errorText: days.text == '0' ? s.reviewAheadMinimumDays : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _validInput
              ? () => Navigator.pop(context, int.parse(days.text))
              : null,
          child: Text(s.create),
        ),
      ],
    );
  }
}

final class _ReviewAheadDialogState extends State<_ReviewAheadDialog> {
  late final TextEditingController days;
  int _queryGeneration = 0;
  bool _hasCards = false;
  bool _checking = false;
  bool _validInput = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDays.clamp(1, widget.maxDays);
    days = TextEditingController(text: initial.toString());
    _refresh(days.text);
  }

  @override
  void dispose() {
    days.dispose();
    super.dispose();
  }

  Future<void> _refresh(String text) async {
    final value = int.tryParse(text);
    final valid = value != null && value >= 1 && value <= widget.maxDays;
    final generation = ++_queryGeneration;
    setState(() {
      _validInput = valid;
      _hasCards = false;
      _checking = valid;
      _error = valid
          ? null
          : (value == 0
                ? AppLocalizations.of(context)!.reviewAheadMinimumDays
                : null);
    });
    if (!valid) return;
    try {
      final found = await widget.hasCards(value);
      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _hasCards = found;
        _checking = false;
        _error = found
            ? null
            : AppLocalizations.of(context)!.customStudyNoCards;
      });
    } on Object {
      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _checking = false;
        _error = AppLocalizations.of(context)!.deckActionFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title ?? s.reviewAhead),
      content: TextField(
        controller: days,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.maxDays.toString().length),
        ],
        onChanged: _refresh,
        decoration: InputDecoration(
          labelText: widget.daysLabel ?? s.reviewAheadDays,
          suffixText: int.tryParse(days.text) == 1 ? s.day : s.days,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: !_validInput || !_hasCards || _checking
              ? null
              : () => Navigator.pop(context, int.parse(days.text)),
          child: Text(s.create),
        ),
      ],
    );
  }
}

final class _CustomStudyTagsDialog extends StatefulWidget {
  const _CustomStudyTagsDialog({
    required this.tags,
    required this.initialSelectedIndex,
    required this.onSelectedIndexChanged,
  });
  final List<String> tags;
  final int initialSelectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  @override
  State<_CustomStudyTagsDialog> createState() => _CustomStudyTagsDialogState();
}

final class _CustomStudyTagsDialogState extends State<_CustomStudyTagsDialog> {
  late CustomStudyCardState state;
  final count = TextEditingController(text: '100');
  final included = <String>{};
  final excluded = <String>{};
  String? inputError;
  @override
  void initState() {
    super.initState();
    state =
        CustomStudyCardState.values[widget.initialSelectedIndex == -1
            ? 0
            : widget.initialSelectedIndex];
    SharedPreferencesAsync().getInt('amountOfCards').then((saved) {
      if (mounted && saved != null && count.text == '100') {
        count.text = saved.toString();
      }
    });
  }

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(s.customStudyCardStateOrTag),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CustomStudyCardState>(
                initialValue: state,
                items: [
                  DropdownMenuItem(
                    value: CustomStudyCardState.NewCardsOnly,
                    child: Text(s.customStudyNewCardsOnly),
                  ),
                  DropdownMenuItem(
                    value: CustomStudyCardState.DueCardsOnly,
                    child: Text(s.customStudyDueCardsOnly),
                  ),
                  DropdownMenuItem(
                    value: CustomStudyCardState.ReviewCardsRandom,
                    child: Text(s.customStudyReviewCardsRandom),
                  ),
                  DropdownMenuItem(
                    value: CustomStudyCardState.AllCardsRandom,
                    child: Text(s.customStudyAllCardsRandom),
                  ),
                ],
                onChanged: (v) => setState(() {
                  state = v ?? state;
                  widget.onSelectedIndexChanged(state.index);
                }),
              ),
              TextField(
                controller: count,
                onChanged: (_) => setState(() => inputError = null),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.customStudyCardsToStudy,
                  errorText: inputError,
                ),
              ),
              Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 48,
                    child: Text(
                      s.customStudyInclude,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      s.customStudyExclude,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              for (final tag in widget.tags)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16.0 * (tag.split('::').length - 1),
                        ),
                        child: Text(tag),
                      ),
                    ),
                    Checkbox(
                      semanticLabel: s.customStudyIncludeTag(tag),
                      value: included.contains(tag),
                      onChanged: (v) => setState(() {
                        inputError = null;
                        if (v == true) {
                          included.add(tag);
                          excluded.remove(tag);
                        } else {
                          included.remove(tag);
                        }
                      }),
                    ),
                    Checkbox(
                      semanticLabel: s.customStudyExcludeTag(tag),
                      value: excluded.contains(tag),
                      onChanged: (v) => setState(() {
                        inputError = null;
                        if (v == true) {
                          excluded.add(tag);
                          included.remove(tag);
                        } else {
                          excluded.remove(tag);
                        }
                      }),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final limit = int.tryParse(count.text);
            if (limit == null ||
                limit < 1 ||
                limit > 0x7fffffff ||
                included.length + excluded.length > 100) {
              setState(
                () => inputError = included.length + excluded.length > 100
                    ? s.customStudyTooManyTags
                    : s.customStudyPositiveCount,
              );
              return;
            }
            Navigator.pop(
              context,
              CustomStudyTagsRequest(
                state: state,
                cardLimit: limit,
                includedTags: included.toList(),
                excludedTags: excluded.toList(),
              ),
            );
          },
          child: Text(s.create),
        ),
      ],
    );
  }
}
