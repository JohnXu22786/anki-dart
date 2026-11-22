// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/deck_config.pbenum.dart' as proto;
import 'package:fixnum/fixnum.dart';

import 'ids.dart';
import 'review_queue.dart';

/// Candidate data needed to apply Core's new-card sort order without loading
/// or mutating the source cards.
class MainQueueSortCandidate {
  const MainQueueSortCandidate({
    required this.id,
    required this.noteId,
    required this.templateIndex,
    required this.mtime,
  });

  final CardId id;
  final NoteId noteId;
  final int templateIndex;
  final TimestampSecs mtime;
}

enum MainQueueEntryKind { newCard, interdayLearning, review }

/// An item in Core's main queue. Intraday learning entries are kept in the
/// separate learning queue and are not represented here.
class MainQueueEntry {
  const MainQueueEntry({
    required this.id,
    required this.mtime,
    required this.kind,
  });

  final CardId id;
  final TimestampSecs mtime;
  final MainQueueEntryKind kind;
}

/// Returns candidates in the configured Core order, preserving ties in their
/// original gather order. [daysElapsed] is the deterministic hash salt.
List<MainQueueSortCandidate> sortNewQueueCandidates(
  List<MainQueueSortCandidate> candidates,
  proto.DeckConfig_Config_NewCardSortOrder sortOrder, {
  required int daysElapsed,
}) {
  final indexed = [
    for (var index = 0; index < candidates.length; index++)
      (candidate: candidates[index], index: index),
  ];

  int compareIndexed(
    ({MainQueueSortCandidate candidate, int index}) one,
    ({MainQueueSortCandidate candidate, int index}) two,
  ) {
    final a = one.candidate;
    final b = two.candidate;
    final comparison = switch (sortOrder) {
      proto.DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_NO_SORT => 0,
      proto.DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_TEMPLATE =>
        a.templateIndex.compareTo(b.templateIndex),
      proto.DeckConfig_Config_NewCardSortOrder
            .NEW_CARD_SORT_ORDER_TEMPLATE_THEN_RANDOM =>
        _compareInt(a.templateIndex, b.templateIndex) != 0
            ? _compareInt(a.templateIndex, b.templateIndex)
            : _hashCardId(a.id, daysElapsed)
                .compareTo(_hashCardId(b.id, daysElapsed)),
      proto.DeckConfig_Config_NewCardSortOrder
            .NEW_CARD_SORT_ORDER_RANDOM_NOTE_THEN_TEMPLATE =>
        _hashCardId(a.noteId, daysElapsed)
                    .compareTo(_hashCardId(b.noteId, daysElapsed)) !=
                0
            ? _hashCardId(a.noteId, daysElapsed)
                .compareTo(_hashCardId(b.noteId, daysElapsed))
            : _compareInt(a.templateIndex, b.templateIndex),
      proto.DeckConfig_Config_NewCardSortOrder
            .NEW_CARD_SORT_ORDER_RANDOM_CARD =>
        _hashCardId(a.id, daysElapsed)
            .compareTo(_hashCardId(b.id, daysElapsed)),
      _ => throw ArgumentError.value(sortOrder, 'sortOrder'),
    };
    return comparison != 0 ? comparison : one.index.compareTo(two.index);
  }

  indexed.sort(compareIndexed);
  return [for (final entry in indexed) entry.candidate];
}

/// Builds Core's main queue from already ordered candidate lists.
///
/// Reviews and day-learning candidates retain their supplied order. New cards
/// are sorted according to [sortOrder]. The day-learning and new-card mixes
/// are applied as separate composition stages. Caller-owned lists are never
/// changed.
List<MainQueueEntry> composeMainQueue({
  required List<ReviewQueueEntry> reviews,
  required List<ReviewQueueEntry> dayLearning,
  required List<MainQueueSortCandidate> newCards,
  required proto.DeckConfig_Config_NewCardSortOrder sortOrder,
  required int daysElapsed,
  required proto.DeckConfig_Config_ReviewMix dayLearningMix,
  required proto.DeckConfig_Config_ReviewMix newReviewMix,
}) {
  final reviewEntries = [
    for (final entry in reviews)
      MainQueueEntry(
        id: entry.id,
        mtime: entry.mtime,
        kind: MainQueueEntryKind.review,
      ),
  ];
  final dayLearningEntries = [
    for (final entry in dayLearning)
      MainQueueEntry(
        id: entry.id,
        mtime: entry.mtime,
        kind: MainQueueEntryKind.interdayLearning,
      ),
  ];

  final withDayLearning = _mergeReviewMix(
    reviewEntries,
    dayLearningEntries,
    dayLearningMix,
  );
  final newEntries = [
    for (final candidate in sortNewQueueCandidates(
      newCards,
      sortOrder,
      daysElapsed: daysElapsed,
    ))
      MainQueueEntry(
        id: candidate.id,
        mtime: candidate.mtime,
        kind: MainQueueEntryKind.newCard,
      ),
  ];

  return switch (newReviewMix.value) {
    0 => interspersedQueues(withDayLearning, newEntries),
    1 => [...withDayLearning, ...newEntries],
    2 => [...newEntries, ...withDayLearning],
    _ => throw ArgumentError.value(newReviewMix, 'newReviewMix'),
  };
}

List<MainQueueEntry> _mergeReviewMix(
  List<MainQueueEntry> reviews,
  List<MainQueueEntry> dayLearning,
  proto.DeckConfig_Config_ReviewMix mix,
) =>
    switch (mix.value) {
      0 => interspersedQueues(reviews, dayLearning),
      1 => [...reviews, ...dayLearning],
      2 => [...dayLearning, ...reviews],
      _ => throw ArgumentError.value(mix, 'dayLearningMix'),
    };

int _compareInt(int one, int two) => one.compareTo(two);

BigInt _hashCardId(Int64 id, int salt) {
  const prime = 0x100000001b3;
  final mask = (BigInt.one << 64) - BigInt.one;
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);

  for (final value in [id, Int64(salt)]) {
    // Int64.toBytes() returns the signed value as its little-endian two's
    // complement representation, matching Rust Hasher.write_i64().
    for (final byte in value.toBytes()) {
      hash = ((hash ^ BigInt.from(byte)) * BigInt.from(prime)) & mask;
    }
  }
  return hash;
}
