/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_backend_protocol/anki/decks.pb.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/anki_dart.dart' show FilteredDeckOptions;
import 'package:fixnum/fixnum.dart';

import 'collection_runtime.dart';
import 'deck_picker_screen.dart';

/// Collection-backed Deck Picker projection shared by all Flutter targets.
/// Unsupported feature routes fail visibly until their backend units are
/// implemented; successful-looking placeholder actions are not emitted.
final class CollectionDeckPickerRepository implements DeckPickerRepository {
  const CollectionDeckPickerRepository(this.collections);

  final CollectionRuntime collections;

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
  FilteredDeckOptions get newFilteredDeckOptions => const FilteredDeckOptions();

  @override
  List<FilteredDeckOrderOption> get filteredDeckOrderOptions => const [];

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
    await selectDeck(deckId);
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
  Future<void> performAction(DeckPickerAction action, int deckId) =>
      Future.error(
        UnsupportedError('Deck action ${action.name} is not implemented yet.'),
      );

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
  Future<void> buildFilteredDeck(FilteredDeckRequest request) => Future.error(
    UnsupportedError('Filtered deck scheduling is not implemented yet.'),
  );
}
