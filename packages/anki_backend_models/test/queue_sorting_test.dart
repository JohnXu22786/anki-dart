// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pbenum.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

MainQueueSortCandidate _candidate(
  int id, {
  int noteId = 1,
  int templateIndex = 0,
  int mtime = 0,
}) =>
    _candidate64(
      Int64(id),
      noteId: Int64(noteId),
      templateIndex: templateIndex,
      mtime: Int64(mtime),
    );

MainQueueSortCandidate _candidate64(
  Int64 id, {
  Int64? noteId,
  int templateIndex = 0,
  Int64? mtime,
}) =>
    MainQueueSortCandidate(
      id: id,
      noteId: noteId ?? Int64.ONE,
      templateIndex: templateIndex,
      mtime: mtime ?? Int64.ZERO,
    );

void main() {
  group('sortNewQueueCandidates', () {
    test('preserves gather order and stably sorts by template index', () {
      final input = [
        _candidate(1, templateIndex: 2),
        _candidate(2, templateIndex: 1),
        _candidate(3, templateIndex: 1),
      ];

      expect(
        sortNewQueueCandidates(
          input,
          proto.DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_NO_SORT,
          daysElapsed: 15,
        ).map((entry) => entry.id.toInt()),
        [1, 2, 3],
      );
      expect(
        sortNewQueueCandidates(
          input,
          proto.DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_TEMPLATE,
          daysElapsed: 15,
        ).map((entry) => entry.id.toInt()),
        [2, 3, 1],
      );
      expect(
        sortNewQueueCandidates(
          input,
          proto.DeckConfig_Config_NewCardSortOrder
              .NEW_CARD_SORT_ORDER_TEMPLATE_THEN_RANDOM,
          daysElapsed: 15,
        ).map((entry) => entry.id.toInt()),
        [3, 2, 1],
      );
      expect(input.map((entry) => entry.id.toInt()), [1, 2, 3]);
    });

    test('uses salted little-endian FNV hashes for exact signed 64-bit IDs',
        () {
      final input = [
        _candidate(1),
        _candidate(2),
        _candidate(-1),
        _candidate64(Int64.parseInt('9007199254740997')),
        _candidate64(Int64.parseInt('-9007199254740997')),
      ];

      expect(
        sortNewQueueCandidates(
          input,
          proto.DeckConfig_Config_NewCardSortOrder
              .NEW_CARD_SORT_ORDER_RANDOM_CARD,
          daysElapsed: 2,
        ).map((entry) => entry.id.toString()),
        [
          '9007199254740997',
          '-9007199254740997',
          '1',
          '-1',
          '2',
        ],
      );
      expect(
        sortNewQueueCandidates(
          input,
          proto.DeckConfig_Config_NewCardSortOrder
              .NEW_CARD_SORT_ORDER_RANDOM_CARD,
          daysElapsed: 0,
        ).map((entry) => entry.id.toString()),
        ['2', '-9007199254740997', '1', '-1', '9007199254740997'],
      );
    });

    test(
        'random-note order groups sibling templates and ties preserve input order',
        () {
      final input = [
        _candidate(30, noteId: 20, templateIndex: 1),
        _candidate(10, noteId: 10, templateIndex: 1),
        _candidate(11, noteId: 10, templateIndex: 0),
        _candidate(12, noteId: 10, templateIndex: 0),
      ];

      final sorted = sortNewQueueCandidates(
        input,
        proto.DeckConfig_Config_NewCardSortOrder
            .NEW_CARD_SORT_ORDER_RANDOM_NOTE_THEN_TEMPLATE,
        daysElapsed: 0,
      );
      expect(sorted.map((entry) => entry.id.toInt()), [30, 11, 12, 10]);
    });
  });

  group('composeMainQueue', () {
    test('maps main queue kinds and applies independent mix policies', () {
      final reviews = [
        ReviewQueueEntry(
          id: Int64(1),
          mtime: Int64(11),
          kind: ReviewQueueEntryKind.review,
        ),
        ReviewQueueEntry(
          id: Int64(2),
          mtime: Int64(22),
          kind: ReviewQueueEntryKind.review,
        ),
      ];
      final dayLearning = [
        ReviewQueueEntry(
          id: Int64(3),
          mtime: Int64(33),
          kind: ReviewQueueEntryKind.learning,
        ),
      ];
      final newCards = [_candidate(4, mtime: 44)];

      final queue = composeMainQueue(
        reviews: reviews,
        dayLearning: dayLearning,
        newCards: newCards,
        sortOrder: proto
            .DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_NO_SORT,
        daysElapsed: 0,
        dayLearningMix:
            proto.DeckConfig_Config_ReviewMix.REVIEW_MIX_BEFORE_REVIEWS,
        newReviewMix:
            proto.DeckConfig_Config_ReviewMix.REVIEW_MIX_AFTER_REVIEWS,
      );

      expect(queue.map((entry) => entry.id.toInt()), [3, 1, 2, 4]);
      expect(queue.map((entry) => entry.kind), [
        MainQueueEntryKind.interdayLearning,
        MainQueueEntryKind.review,
        MainQueueEntryKind.review,
        MainQueueEntryKind.newCard,
      ]);
      expect(queue.map((entry) => entry.mtime.toInt()), [33, 11, 22, 44]);
      expect(reviews.map((entry) => entry.id.toInt()), [1, 2]);
      expect(dayLearning.single.id.toInt(), 3);
      expect(newCards.single.id.toInt(), 4);
    });

    test('mixed paths reuse Core interspersing with reviews first', () {
      final reviews = List.generate(
        3,
        (index) => ReviewQueueEntry(
          id: Int64(index + 1),
          mtime: Int64.ZERO,
          kind: ReviewQueueEntryKind.review,
        ),
      );
      final dayLearning = [
        ReviewQueueEntry(
          id: Int64(11),
          mtime: Int64.ZERO,
          kind: ReviewQueueEntryKind.learning,
        ),
        ReviewQueueEntry(
          id: Int64(12),
          mtime: Int64.ZERO,
          kind: ReviewQueueEntryKind.learning,
        ),
      ];

      expect(
        composeMainQueue(
          reviews: reviews,
          dayLearning: dayLearning,
          newCards: const [],
          sortOrder: proto
              .DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_NO_SORT,
          daysElapsed: 0,
          dayLearningMix:
              proto.DeckConfig_Config_ReviewMix.REVIEW_MIX_MIX_WITH_REVIEWS,
          newReviewMix:
              proto.DeckConfig_Config_ReviewMix.REVIEW_MIX_AFTER_REVIEWS,
        ).map((entry) => entry.id.toInt()),
        [1, 11, 2, 12, 3],
      );
    });
  });
}
