/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_backend_protocol/anki/decks.pb.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_models/anki_backend_models.dart'
    show FilteredDeckKind, NormalDeckKind, normalizeDeckName;
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_search_parser/anki_search_parser.dart' show deckSearch;
import 'package:anki_dart/anki_dart.dart'
    show
        FilteredDeckOptions,
        SearchTermState,
        buildCustomStudySearch,
        buildReviewAheadAvailabilitySearch,
        projectTagsDialogInitialization,
        validateCustomStudyInput,
        validateReviewAheadDays;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

import 'collection_runtime.dart';
import 'collection_card_browser_controller.dart';
import 'deck_description_editor.dart';
import 'deck_options_editor.dart';
import 'custom_study_review_ahead_request.dart';
import 'deck_picker_screen.dart';
import 'note_editor_screen.dart';

Int64 _customStudyDeckId(DeckPickerDeck deck) =>
    deck.exactId ??
    (throw StateError('exact deck ID required for Custom Study'));

/// Collection-backed Deck Picker projection shared by all Flutter targets.
/// Unsupported feature routes fail visibly until their backend units are
/// implemented; successful-looking placeholder actions are not emitted.
final class CollectionDeckPickerRepository
    implements
        DeckPickerRepository,
        DeckPickerNewNotePortProvider,
        DeckPickerExactBrowseDeckProvider,
        DeckPickerRenameProvider,
        DeckPickerCreateSubdeckProvider,
        DeckPickerDeleteProvider,
        DeckPickerRebuildFilteredDeckProvider,
        DeckPickerUnburyProvider,
        DeckPickerEmptyFilteredDeckProvider,
        DeckPickerDescriptionProvider,
        DeckPickerCustomStudyProvider,
        DeckPickerReviewAheadProvider,
        DeckPickerDailyLimitsProvider,
        DeckPickerCollectionUndoProvider {
  const CollectionDeckPickerRepository(this.collections);

  final CollectionRuntime collections;

  @override
  Future<NewNoteEditorPort> selectDeckAndCreateNewNotePort(
    DeckPickerDeck deck,
  ) async {
    final storage = _storage;
    final id = deck.exactId ?? Int64(deck.id);
    if (storage.decks.getDeck(id) == null) {
      throw StateError('deck not found: $id');
    }
    await storage.selectDeck(id);
    return CollectionCardBrowserController(
      collections,
      selectedNewNoteDeckId: () => id,
    );
  }

  @override
  Future<NewNoteEditorPort> createNewNotePortForCurrentDeck() =>
      Future.value(CollectionCardBrowserController(collections));

  @override
  Future<void> selectDeckForBrowse(DeckPickerDeck deck) async {
    final id = deck.exactId ?? Int64(deck.id);
    if (_storage.decks.getDeck(id) == null) {
      throw StateError('deck not found: $id');
    }
  }

  CollectionSqliteStorage get _storage {
    final storage = collections.storage;
    if (storage == null || !collections.isInitialized) {
      throw StateError('The active profile collection is not open.');
    }
    return storage;
  }

  @override
  int? get currentDeckId {
    final storage = collections.storage;
    if (storage == null || !collections.isInitialized) return null;
    final id = storage.currentDeckId;
    return storage.decks.getDeck(id) == null ? 1 : id.toInt();
  }

  @override
  bool get scheduleRemindersEnabled => false;

  @override
  FilteredDeckOptions get newFilteredDeckOptions {
    final now = DateTime.now();
    final storage = collections.storage;
    final deck = collections.isInitialized && storage != null
        ? storage.decks.getDeck(storage.currentDeckId)
        : null;
    final defaultSearch = deck == null || deck.kind is FilteredDeckKind
        ? ''
        : deckSearch(deck.name);
    final defaultName =
        'Filtered Deck ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return FilteredDeckOptions(
      name: defaultName,
      title: defaultName,
      filter1State: SearchTermState(
        search: defaultSearch.isEmpty ? '' : '$defaultSearch is:due',
        limit: '100',
        index: 1,
      ),
      filter2State: SearchTermState(
        search: defaultSearch.isEmpty ? '' : '$defaultSearch is:new',
        limit: '20',
        index: 6,
      ),
      delayAgain: '60',
      delayHard: '600',
    );
  }

  @override
  List<FilteredDeckOrderOption> get filteredDeckOrderOptions => const [
    FilteredDeckOrderOption(orderNumber: 0, label: 'Oldest reviewed first'),
    FilteredDeckOrderOption(orderNumber: 1, label: 'Random'),
    FilteredDeckOrderOption(orderNumber: 2, label: 'Intervals ascending'),
    FilteredDeckOrderOption(orderNumber: 3, label: 'Intervals descending'),
    FilteredDeckOrderOption(orderNumber: 4, label: 'Lapses'),
    FilteredDeckOrderOption(orderNumber: 5, label: 'Added'),
    FilteredDeckOrderOption(orderNumber: 6, label: 'Due'),
    FilteredDeckOrderOption(orderNumber: 7, label: 'Reverse added'),
    FilteredDeckOrderOption(orderNumber: 8, label: 'Retrievability ascending'),
    FilteredDeckOrderOption(orderNumber: 9, label: 'Retrievability descending'),
    FilteredDeckOrderOption(orderNumber: 10, label: 'Relative overdueness'),
  ];

  @override
  Future<List<DeckPickerDeck>> loadDecks() async {
    final tree = await _storage.deckTreeForNow();
    return tree.children.map((node) => _project(node, '')).toList();
  }

  DeckPickerDeck _project(DeckTreeNode node, String parentName) {
    final name = parentName.isEmpty ? node.name : '$parentName::${node.name}';
    final id = node.deckId;
    return DeckPickerDeck(
      id: id.toInt(),
      exactId: id,
      name: name,
      newCount: node.newCount,
      learningCount: node.learnCount,
      reviewCount: node.reviewCount,
      collapsed: node.collapsed,
      filtered: node.filtered,
      hasBuried: _storage.deckHasBuriedCards(id),
      children: node.children
          .map((child) => _project(child, name))
          .toList(growable: false),
    );
  }

  @override
  Future<void> selectDeck(int deckId) async {
    final id = Int64(deckId);
    if (_storage.decks.getDeck(id) == null) {
      throw StateError('deck not found: $deckId');
    }
    await _storage.selectDeck(id);
  }

  @override
  Future<void> study(int deckId) async {
    throw UnsupportedError('The Reviewer screen is not implemented yet.');
  }

  @override
  Future<void> toggleDeckExpand(int deckId) async {
    final deck = _storage.decks.getDeck(Int64(deckId));
    if (deck == null) throw StateError('deck not found: $deckId');
    await _storage.setDeckCollapsed(
      deck.id,
      collapsed: !deck.common.studyCollapsed,
    );
  }

  @override
  Future<void> performAction(DeckPickerAction action, int deckId) async {
    if (action == DeckPickerAction.rebuildFilteredDeck) {
      final id = Int64(deckId);
      final deck = _storage.decks.getDeck(id);
      if (deck == null) throw StateError('deck not found: $deckId');
      if (deck.kind case FilteredDeckKind(:final value)) {
        await _storage.buildFilteredDeck(
          deck_proto.FilteredDeckForUpdate(
            id: id,
            name: deck.name,
            config: value.deepCopy(),
            allowEmpty: true,
          ),
        );
        return;
      }
      throw StateError('filtered deck required: $deckId');
    }
    if (action == DeckPickerAction.emptyFilteredDeck) {
      await _storage.emptyFilteredDeck(Int64(deckId));
      return;
    }
    throw UnsupportedError(
      'Deck action ${action.name} is not implemented yet.',
    );
  }

  @override
  Future<List<String>> customStudyTags(DeckPickerDeck deck) async {
    final id = _customStudyDeckId(deck);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) {
      throw StateError('deck not found: $id');
    }
    if (stored.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $id');
    }
    final projection = projectTagsDialogInitialization(
      collectionTags: _storage.tags.allTags().map((tag) => tag.name),
      selectedNoteTags: [await _storage.tagsForDeck(id)],
      isCustomStudying: true,
    );
    projection.tags.sort();
    return projection.tags.copyOfAllTagList();
  }

  @override
  Future<void> createCustomStudy(
    DeckPickerDeck deck,
    CustomStudyTagsRequest request,
  ) async {
    validateCustomStudyInput(
      cardLimit: request.cardLimit,
      includedTags: request.includedTags,
      excludedTags: request.excludedTags,
    );
    final id = _customStudyDeckId(deck);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) {
      throw StateError('deck not found: $id');
    }
    if (stored.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $id');
    }
    final search = buildCustomStudySearch(
      deckName: stored.name,
      state: request.state,
      includedTags: request.includedTags,
      excludedTags: request.excludedTags,
    );
    await _storage.buildFilteredDeck(
      deck_proto.FilteredDeckForUpdate(
        name: 'Custom Study Session ${DateTime.now().millisecondsSinceEpoch}',
        config: deck_proto.Deck_Filtered(reschedule: false)
          ..searchTerms.add(
            deck_proto.Deck_Filtered_SearchTerm(
              search: search,
              limit: request.cardLimit,
              order: deck_proto.Deck_Filtered_SearchTerm_Order.RANDOM,
            ),
          ),
        allowEmpty: false,
      ),
    );
  }

  @override
  Future<bool> hasReviewAheadCards(DeckPickerDeck deck, int days) async {
    final id = _customStudyDeckId(deck);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) throw StateError('deck not found: $id');
    if (stored.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $id');
    }
    return _storage.hasCardsMatchingSearch(
      buildReviewAheadAvailabilitySearch(deckName: stored.name, days: days),
    );
  }

  @override
  Future<void> createReviewAhead(DeckPickerDeck deck, int days) async {
    validateReviewAheadDays(days);
    final id = _customStudyDeckId(deck);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) throw StateError('deck not found: $id');
    if (stored.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $id');
    }
    final existingId =
        _storage.decks.getDeckId('Custom Study Session') ?? Int64.ZERO;
    final existing = existingId == Int64.ZERO
        ? null
        : _storage.decks.getDeck(existingId);
    if (existing != null && existing.kind is! FilteredDeckKind) {
      throw StateError('custom study deck already exists as a normal deck');
    }
    await _storage.buildFilteredDeck(
      reviewAheadFilteredDeckRequest(
        existingSessionId: existingId,
        deckName: stored.name,
        days: days,
      ),
    );
  }

  @override
  Future<DeckDescription> loadDescription(DeckPickerDeck deck) async {
    final id = deck.exactId ?? Int64(deck.id);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) throw StateError('deck not found: $id');
    if (stored.kind is! NormalDeckKind) {
      throw StateError('normal deck required: $id');
    }
    final normal = (stored.kind as NormalDeckKind).value;
    return DeckDescription(
      description: normal.description,
      markdown: normal.markdownDescription,
    );
  }

  @override
  Future<void> saveDescription(
    DeckPickerDeck deck, {
    required String description,
    required bool markdownDescription,
  }) => _storage.updateDeckDescription(
    deck.exactId ?? Int64(deck.id),
    description: description,
    markdownDescription: markdownDescription,
  );

  @override
  Future<DeckDailyLimits> loadDailyLimits(DeckPickerDeck deck) async {
    final id = deck.exactId ?? Int64(deck.id);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) throw StateError('deck not found: $id');
    final configId = stored.configId;
    if (configId == null) throw StateError('normal deck required: $id');
    final config = _storage.deckConfigs.getDeckConfig(configId);
    if (config == null) {
      throw StateError('missing deck configuration: $configId');
    }
    return DeckDailyLimits(
      newPerDay: config.inner.newPerDay,
      reviewsPerDay: config.inner.reviewsPerDay,
    );
  }

  @override
  Future<void> saveDailyLimits(
    DeckPickerDeck deck, {
    required int newPerDay,
    required int reviewsPerDay,
  }) => _storage.updateDeckDailyLimits(
    deck.exactId ?? Int64(deck.id),
    newPerDay: newPerDay,
    reviewsPerDay: reviewsPerDay,
  );

  @override
  bool get canUndoCollectionOperation => _storage.canUndoCollectionOperation;

  @override
  bool get canRedoCollectionOperation => _storage.canRedoCollectionOperation;

  @override
  int get collectionUndoGeneration => _storage.collectionUndoGeneration;

  @override
  Future<void> undoLastCollectionOperation() =>
      _storage.undoLastCollectionOperation();

  @override
  Future<void> redoLastCollectionOperation() =>
      _storage.redoLastCollectionOperation();

  @override
  Future<DeckPickerDeletionResult> deleteDeck(
    DeckPickerDeck deck, {
    required String defaultDeckName,
  }) async {
    final result = await _storage.removeDeckAndChildren(
      deck.exactId ?? Int64(deck.id),
      defaultDeckName: defaultDeckName,
    );
    return DeckPickerDeletionResult(
      deckName: result.deckName,
      cardsDeleted: result.cardsDeleted,
      collectionUndoGeneration: result.collectionUndoGeneration,
      persistenceWarning: result.persistenceWarning,
    );
  }

  @override
  Future<DeckPickerUnburyResult> unburyDeck(DeckPickerDeck deck) async {
    final result = await _storage.unburyDeck(deck.exactId ?? Int64(deck.id));
    return DeckPickerUnburyResult(
      deckName: result.deckName,
      cardsUnburied: result.cardsUnburied,
      collectionUndoGeneration: result.collectionUndoGeneration,
      persistenceWarning: result.persistenceWarning,
    );
  }

  @override
  Future<void> emptyFilteredDeck(DeckPickerDeck deck) async {
    await _storage.emptyFilteredDeck(deck.exactId ?? Int64(deck.id));
  }

  @override
  Future<void> rebuildFilteredDeck(DeckPickerDeck deck) async {
    final id = deck.exactId ?? Int64(deck.id);
    final stored = _storage.decks.getDeck(id);
    if (stored == null) throw StateError('deck not found: $id');
    if (stored.kind case FilteredDeckKind(:final value)) {
      await _storage.buildFilteredDeck(
        deck_proto.FilteredDeckForUpdate(
          id: id,
          name: stored.name,
          config: value.deepCopy(),
          allowEmpty: true,
        ),
      );
      return;
    }
    throw StateError('filtered deck required: $id');
  }

  @override
  bool isDeckNameAvailable(DeckPickerDeck deck, String name) {
    if (name.trim().isEmpty) return false;
    final storage = _storage;
    final normalized = normalizeDeckName(name).replaceAll('::', '\x1f');
    final existingId = storage.decks.getDeckId(normalized);
    final deckId = deck.exactId ?? Int64(deck.id);
    return existingId == null || existingId == deckId;
  }

  @override
  Future<void> renameDeck(DeckPickerDeck deck, String name) async {
    final deckId = deck.exactId ?? Int64(deck.id);
    await _storage.renameDeck(deckId, name);
  }

  @override
  bool isSubdeckNameAvailable(DeckPickerDeck parent, String name) {
    if (name.isEmpty || name.replaceAll('"', '').isEmpty) return false;
    final storage = _storage;
    final parentDeck = storage.decks.getDeck(
      parent.exactId ?? Int64(parent.id),
    );
    if (parentDeck == null || parentDeck.kind is FilteredDeckKind) return true;
    final fullName = normalizeDeckName('${parentDeck.name}::$name');
    final nativeName = fullName.replaceAll('::', '\x1f');
    return storage.decks.getDeckId(nativeName) == null;
  }

  @override
  Future<void> createSubdeck(DeckPickerDeck parent, String name) async {
    await _storage.createSubdeck(parent.exactId ?? Int64(parent.id), name);
  }

  @override
  Future<void> createDeck(String name) async {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name');
    await _storage.getOrCreateNormalDeck(name);
  }

  @override
  Future<void> createSharedDeck() => Future.error(
    UnsupportedError('Shared deck downloads are not implemented yet.'),
  );

  @override
  Future<void> buildFilteredDeck(FilteredDeckRequest request) async {
    int parsedLimit(String value) {
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 0 || parsed > 0x7fffffff) {
        throw ArgumentError.value(
          value,
          'limit',
          'expected a signed 32-bit integer',
        );
      }
      return parsed;
    }

    final term1 = deck_proto.Deck_Filtered_SearchTerm(
      search: request.search1,
      limit: parsedLimit(request.limit1),
      order:
          deck_proto.Deck_Filtered_SearchTerm_Order.valueOf(request.order1) ??
          deck_proto.Deck_Filtered_SearchTerm_Order.OLDEST_REVIEWED_FIRST,
    );
    final terms = <deck_proto.Deck_Filtered_SearchTerm>[term1];
    if (request.secondFilterEnabled) {
      terms.add(
        deck_proto.Deck_Filtered_SearchTerm(
          search: request.search2,
          limit: parsedLimit(request.limit2),
          order:
              deck_proto.Deck_Filtered_SearchTerm_Order.valueOf(
                request.order2,
              ) ??
              deck_proto.Deck_Filtered_SearchTerm_Order.OLDEST_REVIEWED_FIRST,
        ),
      );
    }
    await _storage.buildFilteredDeck(
      deck_proto.FilteredDeckForUpdate(
        id: Int64.ZERO,
        name: request.name,
        allowEmpty: request.allowEmpty,
        config: deck_proto.Deck_Filtered(
          reschedule: request.shouldReschedule,
          searchTerms: terms,
          previewAgainSecs: int.tryParse(request.delayAgain) ?? 60,
          previewHardSecs: int.tryParse(request.delayHard) ?? 600,
          previewGoodSecs: int.tryParse(request.delayGood) ?? 0,
        ),
      ),
    );
  }
}
