// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

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

/// An FSRS training item paired with its optimizer recency weight.
class WeightedFsrsTrainingItem {
  const WeightedFsrsTrainingItem({required this.item, required this.weight});

  /// The original training item instance.
  final FsrsTrainingItem item;

  /// The item's recency weight, rounded with FSRS Core's Float32 arithmetic.
  final double weight;
}

/// Calculates mean recall over each item's current (last) review.
///
/// A current rating greater than 1 counts as a recall, matching FSRS 5.2.0.
/// The ratio uses Core's Float32 arithmetic. Every item must contain at least
/// one review.
double calculateAverageFsrsRecall(List<FsrsTrainingItem> items) {
  if (items.isEmpty) return 0.0;

  var totalRecall = 0;
  for (var index = 0; index < items.length; index++) {
    final reviews = items[index].reviews;
    if (reviews.isEmpty) {
      throw ArgumentError.value(
        index,
        'items',
        'each FSRS training item must contain at least one review',
      );
    }
    if (reviews.last.rating > 1) totalRecall++;
  }

  final storage = Float32List(2);
  storage[0] = totalRecall.toDouble();
  storage[1] = items.length.toDouble();
  storage[0] = storage[0] / storage[1];
  return storage[0];
}

/// Assigns FSRS 5.2.0 recency weights to caller-ordered training [items].
///
/// [items] must already be sorted by review timestamp, oldest first. This
/// projection preserves their order and does not inspect timestamps.
List<WeightedFsrsTrainingItem> weightFsrsTrainingItemsByRecency(
  List<FsrsTrainingItem> items,
) {
  final storage = Float32List(1);
  double f32(double value) {
    storage[0] = value;
    return storage[0];
  }

  final length = math.max(f32(f32(items.length.toDouble()) - 1.0), 1.0);
  final weightedItems = <WeightedFsrsTrainingItem>[];
  for (var index = 0; index < items.length; index++) {
    final position = f32(index.toDouble());
    final ratio = f32(position / length);
    final cube = f32(f32(ratio * ratio) * ratio);
    final scaledCube = f32(0.75 * cube);
    final weight = f32(0.25 + scaledCube);
    weightedItems.add(
      WeightedFsrsTrainingItem(item: items[index], weight: weight),
    );
  }
  return List.unmodifiable(weightedItems);
}

/// Sorts weighted FSRS training items by review-history length, shortest first.
///
/// Items with the same number of reviews retain their input order, matching
/// FSRS 5.2.0's stable `sort_items_by_review_length()`. The returned list is an
/// immutable copy containing the original weighted item instances.
List<WeightedFsrsTrainingItem> sortFsrsTrainingItemsByReviewLength(
  List<WeightedFsrsTrainingItem> items,
) {
  final indexedItems = [
    for (var index = 0; index < items.length; index++)
      (
        index: index,
        reviewCount: items[index].item.reviews.length,
        item: items[index],
      ),
  ];
  indexedItems.sort((left, right) {
    final lengthOrder = left.reviewCount.compareTo(right.reviewCount);
    return lengthOrder != 0 ? lengthOrder : left.index.compareTo(right.index);
  });
  return List.unmodifiable(indexedItems.map((entry) => entry.item));
}

/// Initialization examples and the optimizer's training examples.
///
/// Both lists are immutable snapshots. Their item objects are the same input
/// instances; the contained review histories are not copied.
class FsrsTrainingData {
  FsrsTrainingData({
    required List<FsrsTrainingItem> initializationItems,
    required List<FsrsTrainingItem> trainingItems,
  })  : initializationItems = List.unmodifiable(initializationItems),
        trainingItems = List.unmodifiable(trainingItems);

  /// Items with exactly one long-term review after optional outlier filtering.
  final List<FsrsTrainingItem> initializationItems;

  /// Items supplied to the optimizer after optional outlier filtering.
  final List<FsrsTrainingItem> trainingItems;
}

/// Partitions [items] and optionally applies FSRS 5.2.0's deterministic
/// initialization-dataset outlier filter.
///
/// Setting [filterOutliers] to `false` bypasses filtering and leaves the
/// training set as the non-initialization partition. Each item must contain a
/// valid 1–4 rating history, begin with deltaT zero, and end with a positive
/// deltaT. Core assumes these preconditions and can panic while
/// indexing malformed or empty items; this port instead throws
/// [ArgumentError] at the API boundary.
FsrsTrainingData prepareFsrsTrainingData(
  List<FsrsTrainingItem> items, {
  required bool filterOutliers,
}) {
  for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
    final reviews = items[itemIndex].reviews;
    if (reviews.isEmpty) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'each FSRS training item must contain at least one review',
      );
    }
    if (reviews.first.deltaT != 0) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'the first review deltaT must be zero',
      );
    }
    if (reviews.any((review) => review.deltaT < 0)) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'review deltaT values must not be negative',
      );
    }
    if (reviews.last.deltaT <= 0) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'each FSRS training item must end with a long-term review',
      );
    }
    if (reviews.any((review) => review.rating < 1 || review.rating > 4)) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'review ratings must be between 1 and 4',
      );
    }
  }

  final initializationItems = <FsrsTrainingItem>[];
  final unpartitionedTrainingItems = <FsrsTrainingItem>[];
  for (final item in items) {
    final longTermReviewCount =
        item.reviews.where((review) => review.deltaT > 0).length;
    if (longTermReviewCount == 1) initializationItems.add(item);
    if (longTermReviewCount != 1) unpartitionedTrainingItems.add(item);
  }
  final trainingItems = filterOutliers
      ? List<FsrsTrainingItem>.of(items)
      : unpartitionedTrainingItems;

  if (!filterOutliers || initializationItems.isEmpty) {
    return FsrsTrainingData(
      initializationItems: initializationItems,
      trainingItems: trainingItems,
    );
  }

  final retained = <FsrsTrainingItem>[];
  final removedPairs = <int, Set<int>>{};
  for (var rating = 1; rating <= 4; rating++) {
    final groupsByDelta = <int, List<FsrsTrainingItem>>{};
    for (final item in initializationItems) {
      if (item.reviews.first.rating == rating) {
        groupsByDelta
            .putIfAbsent(
              item.reviews.last.deltaT,
              () => <FsrsTrainingItem>[],
            )
            .add(item);
      }
    }
    final groups = groupsByDelta.entries.toList()
      ..sort((a, b) {
        final sizeOrder = a.value.length.compareTo(b.value.length);
        return sizeOrder != 0 ? sizeOrder : a.key.compareTo(b.key);
      });
    final total = groups.fold<int>(0, (sum, group) => sum + group.value.length);
    final removalTarget = total ~/ 20 > 20 ? total ~/ 20 : 20;
    var removedCount = 0;
    for (final group in groups) {
      final deltaT = group.key;
      final examples = group.value;
      final targetReached = removedCount + examples.length >= removalTarget;
      final withinMaxDelta = deltaT <= (rating == 4 ? 365 : 100);
      if (targetReached && examples.length >= 6 && withinMaxDelta) {
        retained.addAll(examples);
      } else {
        if (!targetReached) removedCount += examples.length;
        removedPairs.putIfAbsent(rating, () => <int>{}).add(deltaT);
      }
    }
  }

  final filteredTrainingItems = trainingItems.where((item) {
    final rating = item.reviews.first.rating;
    final firstLongTermDelta =
        item.reviews.firstWhere((review) => review.deltaT > 0).deltaT;
    return !(removedPairs[rating]?.contains(firstLongTermDelta) ?? false);
  }).toList();

  return FsrsTrainingData(
    initializationItems: retained,
    trainingItems: filteredTrainingItems,
  );
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
