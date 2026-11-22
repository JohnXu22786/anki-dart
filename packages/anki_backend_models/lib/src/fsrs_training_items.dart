// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';

import 'ids.dart';
import 'revlog.dart';

/// One graded answer in an FSRS parameter-training example.
class FsrsTrainingReview {
  const FsrsTrainingReview({required this.rating, required this.deltaT});

  /// The original answer button value from the revlog.
  final int rating;

  /// Whole days since the previous review, using Core's day-boundary math.
  final int deltaT;
}

/// A history prefix ending at a review after a positive interday interval.
class FsrsTrainingItem {
  const FsrsTrainingItem({required this.reviews});

  final List<FsrsTrainingReview> reviews;
}

/// Training examples and the count of retained revlog entries they represent.
class FsrsTrainingItems {
  const FsrsTrainingItems({required this.items, required this.reviewCount});

  /// Items ordered by the timestamp of the review that selected each item.
  final List<FsrsTrainingItem> items;

  /// Core-equivalent count of filtered revlogs for cards with training items.
  final int reviewCount;
}

/// Projects per-card revlog histories into deterministic FSRS training items.
///
/// Each card's entries are ordered by [RevlogId] before projection. [nextDayAt]
/// and revlog IDs use Unix seconds and milliseconds respectively. The cutoff
/// is a millisecond timestamp and uses Core's strict `id > cutoff` comparison
/// when identifying user grades. This prepares examples only; it does not
/// optimize FSRS parameters or access collection storage.
FsrsTrainingItems computeFsrsTrainingItems({
  required List<List<RevlogEntry>> revlogsByCard,
  required TimestampSecs nextDayAt,
  required Int64 ignoreRevlogsBefore,
}) {
  final projections = <_TrainingItemWithId>[];
  var reviewCount = 0;
  for (final cardEntries in revlogsByCard) {
    final projection = _trainingProjection(
      cardEntries,
      nextDayAt,
      ignoreRevlogsBefore,
    );
    if (projection == null) continue;
    reviewCount += projection.reviewCount;
    projections.addAll(projection.items);
  }
  projections.sort((a, b) => a.revlogId.compareTo(b.revlogId));
  return FsrsTrainingItems(
    items: projections.map((projection) => projection.item).toList(),
    reviewCount: reviewCount,
  );
}

_CardTrainingProjection? _trainingProjection(
  List<RevlogEntry> input,
  TimestampSecs nextDayAt,
  Int64 cutoff,
) {
  final entries = List<RevlogEntry>.of(input)
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  int? firstLearn;
  int? firstUserGrade;

  // Match Core's reverse scan: find the last learning group, or the first
  // eligible interday grade after a reset when deciding where history begins.
  for (var index = entries.length - 1; index >= 0; index--) {
    final entry = entries[index];
    if (entry.isCramming) continue;
    final userGraded = entry.hasRating;
    final interday = entry.interval >= 1 || entry.interval <= -86400;
    if (userGraded && entry.id.value > cutoff && interday) {
      firstUserGrade = index;
    }
    if (userGraded && entry.reviewKind == RevlogReviewKind.learning) {
      firstLearn = index;
    } else if (entry.isReset) {
      if (firstLearn != null || firstUserGrade != null) {
        break;
      }
      return null;
    } else if (firstLearn != null) {
      break;
    }
  }

  // Training ignores a whole card if its last learning sequence predates the
  // cutoff; unlike memory-state calculation it does not fall back to SM-2.
  if (firstLearn == null || entries[firstLearn].id.value < cutoff) {
    return null;
  }
  if (firstLearn > 0) entries.removeRange(0, firstLearn);
  entries.removeWhere((entry) => !entry.hasRatingAndAffectsScheduling);
  if (entries.isEmpty) return null;

  final daysElapsed = <int>[
    for (final entry in entries) _daysElapsed(nextDayAt, entry.id.asSecs()),
  ];
  final reviews = <FsrsTrainingReview>[];
  final items = <_TrainingItemWithId>[];
  for (var index = 0; index < entries.length; index++) {
    final deltaT = index == 0 ? 0 : daysElapsed[index - 1] - daysElapsed[index];
    reviews.add(
      FsrsTrainingReview(rating: entries[index].buttonChosen, deltaT: deltaT),
    );
    if (index >= 1 && deltaT > 0) {
      items.add(
        _TrainingItemWithId(
          entries[index].id.value,
          FsrsTrainingItem(reviews: List.unmodifiable(reviews)),
        ),
      );
    }
  }
  if (items.isEmpty) return null;
  // Each prefix contributes the same filtered history count once, matching
  // Core's count aggregation at the per-card projection boundary.
  return _CardTrainingProjection(items, entries.length);
}

int _daysElapsed(TimestampSecs nextDayAt, TimestampSecs reviewAt) {
  final elapsed = (nextDayAt - reviewAt).toInt();
  if (elapsed <= 0) return 0;
  return (elapsed ~/ 86400).toUnsigned(32);
}

class _CardTrainingProjection {
  const _CardTrainingProjection(this.items, this.reviewCount);

  final List<_TrainingItemWithId> items;
  final int reviewCount;
}

class _TrainingItemWithId {
  const _TrainingItemWithId(this.revlogId, this.item);

  final Int64 revlogId;
  final FsrsTrainingItem item;
}
