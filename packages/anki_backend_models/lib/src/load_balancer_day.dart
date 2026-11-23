// SPDX-License-Identifier: AGPL-3.0-or-later
import 'ids.dart';

/// Tracks the cards and note membership for one load-balancer day.
///
/// This is an in-memory helper for caller-supplied card/note pairs. It does not
/// discover siblings across days or derive dates.
class LoadBalancerDay {
  final List<(CardId, NoteId)> _cards = [];
  final Set<NoteId> _notes = {};

  /// Number of cards scheduled for this day.
  int get cardCount => _cards.length;

  /// Adds [cardId] and records [noteId] as present on this day.
  void add(CardId cardId, NoteId noteId) {
    _cards.add((cardId, noteId));
    _notes.add(noteId);
  }

  /// Removes the first card matching [cardId], if present.
  ///
  /// The internal card list uses swap-remove ordering; no collection view is
  /// exposed, so this ordering is not observable by callers. A note remains a
  /// sibling while any card for it remains on this day.
  void remove(CardId cardId) {
    final index = _cards.indexWhere((card) => card.$1 == cardId);
    if (index < 0) {
      return;
    }

    final removedNoteId = _cards[index].$2;
    final lastIndex = _cards.length - 1;
    if (index != lastIndex) {
      _cards[index] = _cards[lastIndex];
    }
    _cards.removeLast();

    if (!_cards.any((card) => card.$2 == removedNoteId)) {
      _notes.remove(removedNoteId);
    }
  }

  /// Returns whether [noteId] is represented by a card on this day.
  bool hasSibling(NoteId noteId) => _notes.contains(noteId);
}
