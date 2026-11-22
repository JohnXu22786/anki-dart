// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

const _nextDayAt = 300000;

RevlogEntry _entry(
  int secs, {
  required int card,
  int rating = 3,
  int interval = 1,
  int ease = 0,
  RevlogReviewKind kind = RevlogReviewKind.review,
}) =>
    RevlogEntry(
      id: RevlogId(Int64(secs * 1000)),
      cardId: Int64(card),
      buttonChosen: rating,
      interval: interval,
      easeFactor: ease,
      reviewKind: kind,
    );

FsrsTrainingItems _project(List<List<RevlogEntry>> revlogs, {int cutoff = 0}) =>
    computeFsrsTrainingItems(
      revlogsByCard: revlogs,
      nextDayAt: Int64(_nextDayAt),
      ignoreRevlogsBefore: Int64(cutoff),
    );

void main() {
  group('FSRS training-item projection', () {
    test(
        'filters cramming and reset history and requires last learning in cutoff',
        () {
      final beforeReset = [
        _entry(10000, card: 1, kind: RevlogReviewKind.learning),
        _entry(20000, card: 1, kind: RevlogReviewKind.review),
      ];
      final reset = _entry(
        30000,
        card: 1,
        rating: 0,
        ease: 0,
        kind: RevlogReviewKind.manual,
      );
      final afterReset = [
        _entry(40000, card: 1, rating: 1, kind: RevlogReviewKind.learning),
        _entry(130000, card: 1, rating: 4, kind: RevlogReviewKind.review),
        _entry(
          170000,
          card: 1,
          rating: 2,
          ease: 0,
          kind: RevlogReviewKind.filtered,
        ),
        _entry(210000, card: 1, rating: 2, kind: RevlogReviewKind.review),
      ];

      final projected = _project([
        [...beforeReset, reset, ...afterReset],
      ], cutoff: 35000000);

      expect(projected.reviewCount, 3);
      expect(projected.items, hasLength(1));
      expect(projected.items.first.reviews.map((r) => r.rating), [1, 4]);
      expect(
        _project([
          [...beforeReset, reset, ...afterReset],
        ], cutoff: 40000000)
            .items,
        hasLength(1),
      );
      expect(
        _project([
          [
            ...beforeReset,
            reset,
            ...afterReset,
          ],
        ], cutoff: 40000001)
            .items,
        isEmpty,
      );
    });

    test(
        'keeps exact ratings and signed intervals while omitting same-day items',
        () {
      final projected = _project([
        [
          _entry(100000, card: 1, rating: 1, kind: RevlogReviewKind.learning),
          _entry(180000, card: 1, rating: 4, interval: -172800),
          _entry(230000, card: 1, rating: 2),
          _entry(250000, card: 1, rating: 3),
        ],
      ]);

      expect(projected.reviewCount, 4);
      expect(projected.items, hasLength(2));
      expect(projected.items[0].reviews.map((r) => r.rating), [1, 4]);
      expect(projected.items[0].reviews.map((r) => r.deltaT), [0, 1]);
      expect(projected.items[1].reviews.map((r) => r.rating), [1, 4, 2]);
      expect(projected.items[1].reviews.map((r) => r.deltaT), [0, 1, 1]);
    });

    test(
        'counts retained entries only for included cards and orders items by RevlogId',
        () {
      final laterCard = [
        _entry(110000, card: 2, rating: 2, kind: RevlogReviewKind.learning),
        _entry(190000, card: 2, rating: 3),
        _entry(220000, card: 2, rating: 4),
      ];
      final earlierCard = [
        _entry(100000, card: 1, rating: 4, kind: RevlogReviewKind.learning),
        _entry(150000, card: 1, rating: 1),
        _entry(200000, card: 1, rating: 2),
      ];
      final noItems = [
        _entry(120000, card: 3, rating: 3),
        _entry(180000, card: 3, rating: 2),
      ];

      final projected = _project([laterCard, noItems, earlierCard]);

      expect(projected.reviewCount, 6);
      expect(projected.items, hasLength(3));
      expect(
          projected.items.map((item) => item.reviews.last.rating), [1, 3, 4]);
      expect(projected.items.map((item) => item.reviews.length), [2, 2, 3]);
    });

    test('returns empty for empty, incomplete, or truncated learning history',
        () {
      expect(_project([]).items, isEmpty);
      expect(_project([[]]).reviewCount, 0);
      expect(
        _project([
          [
            _entry(10000, card: 1, kind: RevlogReviewKind.review),
            _entry(150000, card: 1, kind: RevlogReviewKind.review),
          ],
        ]).items,
        isEmpty,
      );
      expect(
        _project([
          [
            _entry(10000, card: 1, rating: 0, kind: RevlogReviewKind.learning),
            _entry(150000, card: 1, kind: RevlogReviewKind.review),
          ],
        ]).items,
        isEmpty,
      );
      expect(
        _project([
          [
            _entry(10000, card: 1, kind: RevlogReviewKind.learning),
            _entry(150000, card: 1, kind: RevlogReviewKind.review),
            _entry(220000, card: 1, kind: RevlogReviewKind.review),
          ],
        ], cutoff: 50000000)
            .items,
        isEmpty,
      );
    });
  });
}
