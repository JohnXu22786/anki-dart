// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:fixnum/fixnum.dart';

/// A requested APKG selection. At most one limit kind may be supplied.
///
/// [deckIds] must contain the requested deck and its descendants, as resolved
/// by the collection's deck tree. Selecting cards still exports all cards
/// belonging to their notes, matching Anki Core's package gather behavior.
final class ApkgExportLimit {
  ApkgExportLimit({
    this.deckId,
    Iterable<Int64>? deckIds,
    Iterable<Int64>? noteIds,
    Iterable<Int64>? cardIds,
  }) : deckIds = deckIds?.toList(growable: false),
       noteIds = noteIds?.toList(growable: false),
       cardIds = cardIds?.toList(growable: false) {
    final specified = [
      deckId != null,
      this.deckIds != null,
      this.noteIds != null,
      this.cardIds != null,
    ].where((isSet) => isSet).length;
    if (specified > 1) {
      throw ArgumentError('only one APKG selection limit may be supplied');
    }
  }

  final Int64? deckId;
  final List<Int64>? deckIds;
  final List<Int64>? noteIds;
  final List<Int64>? cardIds;
}

/// The card identity fields needed to resolve an APKG export limit.
final class ApkgCardReference {
  const ApkgCardReference({
    required this.id,
    required this.noteId,
    required this.deckId,
  });

  final Int64 id;
  final Int64 noteId;
  final Int64 deckId;
}

/// Resolved notes and cards for an APKG package.
final class ApkgSelection {
  const ApkgSelection({required this.noteIds, required this.cardIds});

  final List<Int64> noteIds;
  final List<Int64> cardIds;
}

/// Options that control collection scheduling, deck configuration, media, and
/// compatibility layout in an APKG export.
final class ApkgExportOptions {
  const ApkgExportOptions({
    this.withScheduling = false,
    this.withDeckConfigs = false,
    this.withMedia = true,
    this.legacy = false,
  });

  final bool withScheduling;
  final bool withDeckConfigs;
  final bool withMedia;
  final bool legacy;
}

/// Resolves whole-collection, deck, note, or card limits without narrowing IDs.
///
/// A card limit first identifies its notes, then includes every card belonging
/// to those notes. A deck limit similarly identifies notes from cards in the
/// selected deck tree and includes their sibling cards.
ApkgSelection resolveApkgSelection({
  required Iterable<Int64> notes,
  required Iterable<ApkgCardReference> cards,
  ApkgExportLimit? limit,
}) {
  final noteIds = notes.toSet();
  final cardsById = <Int64, ApkgCardReference>{};
  for (final card in cards) {
    if (!noteIds.contains(card.noteId)) {
      throw ArgumentError.value(card.noteId, 'cards.noteId', 'unknown note ID');
    }
    if (cardsById.containsKey(card.id)) {
      throw ArgumentError.value(card.id, 'cards.id', 'duplicate card ID');
    }
    cardsById[card.id] = card;
  }

  final selectedNotes = <Int64>{};
  if (limit == null ||
      (limit.deckIds == null &&
          limit.deckId == null &&
          limit.noteIds == null &&
          limit.cardIds == null)) {
    selectedNotes.addAll(noteIds);
  } else if (limit.noteIds case final requested?) {
    for (final id in requested) {
      if (!noteIds.contains(id)) {
        throw ArgumentError.value(id, 'noteIds', 'unknown note ID');
      }
      selectedNotes.add(id);
    }
  } else if (limit.cardIds case final requested?) {
    for (final id in requested) {
      final card = cardsById[id];
      if (card == null) {
        throw ArgumentError.value(id, 'cardIds', 'unknown card ID');
      }
      selectedNotes.add(card.noteId);
    }
  } else if (limit.deckId case final requested?) {
    for (final card in cardsById.values) {
      if (card.deckId == requested) selectedNotes.add(card.noteId);
    }
  } else if (limit.deckIds case final requested?) {
    final deckIds = requested.toSet();
    for (final card in cardsById.values) {
      if (deckIds.contains(card.deckId)) selectedNotes.add(card.noteId);
    }
  }

  final selectedCards =
      cardsById.values
          .where((card) => selectedNotes.contains(card.noteId))
          .map((card) => card.id)
          .toList()
        ..sort();
  final orderedNotes = selectedNotes.toList()..sort();
  return ApkgSelection(noteIds: orderedNotes, cardIds: selectedCards);
}
