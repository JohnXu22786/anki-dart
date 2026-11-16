// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

/// Builds the deck tree returned by Anki Core's `Collection.deck_tree()` from
/// source ordered deck rows, scheduler due counts, and deck limits.
///
/// The caller supplies counts for the selected timestamp. This keeps clock,
/// rollover, and rollover-unbury decisions in the scheduler while applying the
/// same hierarchy, default-deck, collapse, filtered-deck, and limit rules as
/// Core's tree builder.
proto.DeckTreeNode buildCoreDeckTree({
  required List<Deck> decksInNameOrder,
  required Map<Int64, proto.DeckTreeNode> dueCountsByDeck,
  required Map<Int64, DeckConfig> deckConfigs,
  required int today,
  bool defaultDeckIsEmpty = true,
  bool browser = false,
  bool newCardsIgnoreReviewLimit = false,
  bool applyAllParentLimits = false,
}) {
  final tree = proto.DeckTreeNode();
  _addChildNodes(decksInNameOrder, _DeckCursor(), tree, browser);

  _copyDueCounts(tree, dueCountsByDeck);
  if (defaultDeckIsEmpty) _hideEmptyDefaultDeck(tree);
  final limits = <Int64, _RemainingLimits>{};
  for (final deck in decksInNameOrder) {
    limits[deck.id] = _remainingLimits(
      deck,
      deck.configId == null ? null : deckConfigs[deck.configId],
      today,
      newCardsIgnoreReviewLimit,
    );
  }
  _sumAndCap(
    tree,
    limits,
    applyAllParentLimits ? const _RemainingLimits() : null,
  );
  return tree;
}

void _addChildNodes(
  List<Deck> decks,
  _DeckCursor cursor,
  proto.DeckTreeNode parent,
  bool browser,
) {
  while (cursor.index < decks.length) {
    final deck = decks[cursor.index];
    final components = deck.name.split('::');
    final depth = components.length < 99 ? components.length : 99;
    if (depth <= parent.level) return;
    if (depth == parent.level + 1) {
      parent.children.add(
        _nodeFor(deck, components[depth - 1], depth, browser),
      );
      cursor.index++;
    } else if (parent.children.isNotEmpty) {
      _addChildNodes(decks, cursor, parent.children.last, browser);
    } else {
      // No prior node can own the malformed descendant, so skip it as Core
      // does until collection sanity checks repair the missing hierarchy.
      cursor.index++;
    }
  }
}

final class _DeckCursor {
  int index = 0;
}

proto.DeckTreeNode _nodeFor(Deck deck, String name, int level, bool browser) {
  final kind = deck.kind;
  return proto.DeckTreeNode(
    deckId: deck.id,
    name: name,
    level: level,
    collapsed: browser
        ? deck.common.browserCollapsed
        : deck.common.studyCollapsed,
    filtered: kind is FilteredDeckKind,
  );
}

void _copyDueCounts(
  proto.DeckTreeNode node,
  Map<Int64, proto.DeckTreeNode> counts,
) {
  final source = counts[node.deckId];
  if (source != null) {
    node
      ..newCount = source.newCount
      ..reviewCount = source.reviewCount
      ..learnCount = source.learnCount
      ..intradayLearning = source.intradayLearning
      ..interdayLearningUncapped = source.interdayLearningUncapped
      ..newUncapped = source.newUncapped
      ..reviewUncapped = source.reviewUncapped
      ..totalInDeck = source.totalInDeck;
  }
  for (final child in node.children) {
    _copyDueCounts(child, counts);
  }
}

void _hideEmptyDefaultDeck(proto.DeckTreeNode node) {
  for (var index = 0; index < node.children.length; index++) {
    final child = node.children[index];
    if (child.deckId == 1 && child.children.isEmpty) {
      if (!(child.level == 1 && node.children.length == 1)) {
        node.children.removeAt(index);
      }
      return;
    }
  }
}

_RemainingLimits _remainingLimits(
  Deck deck,
  DeckConfig? config,
  int today,
  bool ignoreReviewLimit,
) {
  if (deck.kind is! NormalDeckKind || config == null) {
    return const _RemainingLimits();
  }
  final normal = (deck.kind as NormalDeckKind).value;
  final reviewLimit =
      normal.hasReviewLimitToday() && normal.reviewLimitToday.today == today
      ? normal.reviewLimitToday.limit
      : normal.hasReviewLimit()
      ? normal.reviewLimit
      : config.inner.reviewsPerDay;
  final newLimit =
      normal.hasNewLimitToday() && normal.newLimitToday.today == today
      ? normal.newLimitToday.limit
      : normal.hasNewLimit()
      ? normal.newLimit
      : config.inner.newPerDay;
  final studied = deck.common.lastDayStudied == today;
  var remainingReview = reviewLimit - (studied ? deck.common.reviewStudied : 0);
  var remainingNew = newLimit - (studied ? deck.common.newStudied : 0);
  if (!ignoreReviewLimit) {
    remainingReview -= studied ? deck.common.newStudied : 0;
    if (remainingNew > remainingReview) remainingNew = remainingReview;
  }
  if (remainingReview < 0) remainingReview = 0;
  if (remainingNew < 0) remainingNew = 0;
  return _RemainingLimits(
    review: remainingReview,
    newCards: remainingNew,
    capNewToReview: !ignoreReviewLimit,
  );
}

_NodeCounts _sumAndCap(
  proto.DeckTreeNode node,
  Map<Int64, _RemainingLimits> limits,
  _RemainingLimits? parentLimits,
) {
  var remaining = limits[node.deckId] ?? const _RemainingLimits();
  if (parentLimits != null) {
    remaining = remaining.capTo(parentLimits);
  }
  var uncapped = _NodeCounts(
    newCards: node.newCount,
    review: node.reviewCount,
    intraday: node.intradayLearning,
    interday: node.interdayLearningUncapped,
    total: node.totalInDeck,
  );
  var totalIncludingChildren = node.totalInDeck;
  for (final child in node.children) {
    final childCounts = _sumAndCap(
      child,
      limits,
      parentLimits == null ? null : remaining,
    );
    uncapped.add(childCounts);
    totalIncludingChildren += child.totalIncludingChildren;
  }
  final capped = uncapped.capTo(remaining);
  node
    ..newCount = capped.newCards
    ..reviewCount = capped.review
    ..learnCount = capped.intraday + capped.interday
    ..totalIncludingChildren = totalIncludingChildren;
  return capped;
}

final class _RemainingLimits {
  const _RemainingLimits({
    this.review = 9999,
    this.newCards = 9999,
    this.capNewToReview = false,
  });
  final int review;
  final int newCards;
  final bool capNewToReview;

  _RemainingLimits capTo(_RemainingLimits other) => _RemainingLimits(
    review: review < other.review ? review : other.review,
    newCards: newCards < other.newCards ? newCards : other.newCards,
    capNewToReview: capNewToReview,
  );
}

final class _NodeCounts {
  _NodeCounts({
    required this.newCards,
    required this.review,
    required this.intraday,
    required this.interday,
    required this.total,
  });
  int newCards;
  int review;
  int intraday;
  int interday;
  int total;

  _NodeCounts capTo(_RemainingLimits remaining) {
    var interday = this.interday < remaining.review
        ? this.interday
        : remaining.review;
    var reviewsLeft = remaining.review - interday;
    var review = this.review < reviewsLeft ? this.review : reviewsLeft;
    var newCards = this.newCards < remaining.newCards
        ? this.newCards
        : remaining.newCards;
    if (remaining.capNewToReview) {
      reviewsLeft -= review;
      if (newCards > reviewsLeft) newCards = reviewsLeft;
    }
    return _NodeCounts(
      newCards: newCards,
      review: review,
      intraday: intraday,
      interday: interday,
      total: total,
    );
  }

  void add(_NodeCounts other) {
    newCards += other.newCards;
    review += other.review;
    intraday += other.intraday;
    interday += other.interday;
    total += other.total;
  }
}
