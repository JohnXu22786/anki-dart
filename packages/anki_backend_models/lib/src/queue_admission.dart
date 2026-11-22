// SPDX-License-Identifier: AGPL-3.0-or-later

/// Per-deck sibling bury settings, resolved by the caller from deck configs.
class QueueBuryMode {
  const QueueBuryMode({
    this.buryNew = false,
    this.buryReviews = false,
    this.buryInterdayLearning = false,
  });

  final bool buryNew;
  final bool buryReviews;
  final bool buryInterdayLearning;

  QueueBuryMode merge(QueueBuryMode other) => QueueBuryMode(
        buryNew: buryNew || other.buryNew,
        buryReviews: buryReviews || other.buryReviews,
        buryInterdayLearning:
            buryInterdayLearning || other.buryInterdayLearning,
      );
}

/// A pre-gathered candidate. IDs are kept as opaque values and candidate
/// ordering is supplied by the caller, which owns collection queries/sorting.
class QueueCandidate<CardIdT, NoteIdT, DeckIdT> {
  const QueueCandidate({
    required this.cardId,
    required this.noteId,
    required this.currentDeckId,
    required this.originalDeckId,
    required this.buryMode,
  });

  final CardIdT cardId;
  final NoteIdT noteId;
  final DeckIdT currentDeckId;
  final DeckIdT originalDeckId;
  final QueueBuryMode buryMode;
}

enum NewCardGatherPath { sorted, byDeck }

/// Scheduler time used to prepare the supplied candidate sequences.
class QueueAdmissionTime {
  const QueueAdmissionTime({
    required this.nowSecs,
    required this.daysElapsed,
    required this.nextDayAtSecs,
  });

  final int nowSecs;
  final int daysElapsed;
  final int nextDayAtSecs;
}

/// Remaining review/new capacity for a non-root deck or parent. Null is unlimited.
class QueueDeckLimit {
  const QueueDeckLimit({this.review, this.newCards});

  final int? review;
  final int? newCards;
}

/// Explicit queue admission inputs. Candidate lists are already selected and
/// ordered by the host; this model does no storage access or sorting.
class QueueAdmissionInput<CardIdT, NoteIdT, DeckIdT> {
  const QueueAdmissionInput({
    required this.time,
    required this.rootDeckId,
    this.intradayCandidatesForBuryState = const [],
    this.dayLearningCandidates = const [],
    this.reviewCandidates = const [],
    this.newCandidates = const [],
    this.newCandidatesByDeck = const {},
    this.newDeckOrder = const [],
    this.newGatherPath = NewCardGatherPath.sorted,
    required this.newCardsIgnoreReviewLimit,
    this.rootReviewLimit,
    this.rootNewLimit,
    this.deckLimits = const {},
    this.parentDeckIds = const {},
  });

  final QueueAdmissionTime time;
  final DeckIdT rootDeckId;

  /// Earlier gathered intraday cards seed sibling bury state, but stay in
  /// Unit73's existing queue and are never returned by this admission pass.
  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>>
      intradayCandidatesForBuryState;
  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>> dayLearningCandidates;
  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>> reviewCandidates;
  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>> newCandidates;
  final Map<DeckIdT, List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>>>
      newCandidatesByDeck;
  final List<DeckIdT> newDeckOrder;
  final NewCardGatherPath newGatherPath;

  /// Core's global switch that disables review-to-new daily-limit coupling.
  final bool newCardsIgnoreReviewLimit;
  final int? rootReviewLimit;
  final int? rootNewLimit;

  /// Current deck and non-root parent capacities; root capacity is separate.
  final Map<DeckIdT, QueueDeckLimit> deckLimits;
  final Map<DeckIdT, DeckIdT?> parentDeckIds;
}

/// Candidates admitted by Core's day-learning, review, and new gather passes.
class QueueAdmissionResult<CardIdT, NoteIdT, DeckIdT> {
  const QueueAdmissionResult({
    required this.dayLearning,
    required this.reviews,
    required this.newCards,
  });

  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>> dayLearning;
  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>> reviews;
  final List<QueueCandidate<CardIdT, NoteIdT, DeckIdT>> newCards;
}

/// Applies Core-compatible admission to already gathered candidate sequences.
///
/// Intraday candidates first seed sibling bury state, then day-learning
/// (interday learning) candidates are admitted and share the review limits.
/// Review candidates follow, then new candidates. A note's bury flags are
/// accumulated from each encountered sibling; the previously accumulated mode
/// decides whether the current sibling is buried, matching Core's
/// `get_and_update_bury_mode_for_note()` behavior.
QueueAdmissionResult<CardIdT, NoteIdT, DeckIdT>
    admitQueueCandidates<CardIdT, NoteIdT, DeckIdT>(
        QueueAdmissionInput<CardIdT, NoteIdT, DeckIdT> input) {
  final admittedDayLearning = <QueueCandidate<CardIdT, NoteIdT, DeckIdT>>[];
  final admittedReviews = <QueueCandidate<CardIdT, NoteIdT, DeckIdT>>[];
  final admittedNew = <QueueCandidate<CardIdT, NoteIdT, DeckIdT>>[];
  final seenNotes = <NoteIdT, QueueBuryMode>{};
  final remainingReview = <DeckIdT, int?>{
    for (final entry in input.deckLimits.entries)
      if (entry.key != input.rootDeckId) entry.key: entry.value.review,
  };
  final remainingNew = <DeckIdT, int?>{
    for (final entry in input.deckLimits.entries)
      if (entry.key != input.rootDeckId) entry.key: entry.value.newCards,
  };
  var rootReview = input.rootReviewLimit;
  var rootNew = input.rootNewLimit;
  if (!input.newCardsIgnoreReviewLimit) {
    for (final deckId in remainingNew.keys) {
      remainingNew[deckId] = _minLimit(
        remainingNew[deckId],
        remainingReview[deckId],
      );
    }
    rootNew = _minLimit(rootNew, rootReview);
  }

  void decrementReviewAndParents(DeckIdT deckId) {
    _decrementReviewAndParents(
      deckId,
      remainingReview,
      remainingNew,
      input.parentDeckIds,
      input.rootDeckId,
      capNewToReview: !input.newCardsIgnoreReviewLimit,
    );
    if (rootReview != null) {
      rootReview = rootReview! - 1;
      if (!input.newCardsIgnoreReviewLimit) {
        rootNew = _minLimit(rootNew, rootReview);
      }
    }
  }

  void encounter(QueueCandidate<CardIdT, NoteIdT, DeckIdT> candidate) {
    final previous = seenNotes[candidate.noteId];
    seenNotes[candidate.noteId] = (previous ?? const QueueBuryMode()).merge(
      candidate.buryMode,
    );
  }

  bool buried(
    QueueCandidate<CardIdT, NoteIdT, DeckIdT> candidate,
    bool Function(QueueBuryMode) flag,
  ) {
    final previous = seenNotes[candidate.noteId];
    encounter(candidate);
    return previous != null && flag(previous);
  }

  for (final candidate in input.intradayCandidatesForBuryState) {
    encounter(candidate);
  }

  for (final candidate in input.dayLearningCandidates) {
    if (rootReview == 0) break;
    if (_deckOrParentLimitReached(
      candidate.currentDeckId,
      remainingReview,
      input.parentDeckIds,
      input.rootDeckId,
    )) {
      continue;
    }
    final shouldBury = buried(candidate, (mode) => mode.buryInterdayLearning);
    if (!shouldBury) {
      admittedDayLearning.add(candidate);
      decrementReviewAndParents(candidate.currentDeckId);
    }
  }

  for (final candidate in input.reviewCandidates) {
    if (rootReview == 0) break;
    if (_deckOrParentLimitReached(
      candidate.currentDeckId,
      remainingReview,
      input.parentDeckIds,
      input.rootDeckId,
    )) {
      continue;
    }
    final shouldBury = buried(candidate, (mode) => mode.buryReviews);
    if (!shouldBury) {
      admittedReviews.add(candidate);
      decrementReviewAndParents(candidate.currentDeckId);
    }
  }

  if (input.newGatherPath == NewCardGatherPath.sorted) {
    for (final candidate in input.newCandidates) {
      if (rootNew == 0) break;
      if (_deckOrParentLimitReached(
        candidate.currentDeckId,
        remainingNew,
        input.parentDeckIds,
        input.rootDeckId,
      )) {
        continue;
      }
      final shouldBury = buried(candidate, (mode) => mode.buryNew);
      if (!shouldBury) {
        admittedNew.add(candidate);
        _decrementDeckAndParents(
          candidate.currentDeckId,
          remainingNew,
          input.parentDeckIds,
          input.rootDeckId,
        );
        if (rootNew != null) rootNew = rootNew! - 1;
      }
    }
  } else {
    for (final deckId in input.newDeckOrder) {
      if (rootNew == 0) break;
      if (_deckOrParentLimitReached(
        deckId,
        remainingNew,
        input.parentDeckIds,
        input.rootDeckId,
      )) {
        continue;
      }
      for (final candidate in input.newCandidatesByDeck[deckId] ?? const []) {
        if (rootNew == 0) break;
        if (_deckOrParentLimitReached(
          deckId,
          remainingNew,
          input.parentDeckIds,
          input.rootDeckId,
        )) {
          // Core's by-deck callback stops this deck's iterator at its limit.
          break;
        }
        final shouldBury = buried(candidate, (mode) => mode.buryNew);
        if (!shouldBury) {
          admittedNew.add(candidate);
          _decrementDeckAndParents(
            deckId,
            remainingNew,
            input.parentDeckIds,
            input.rootDeckId,
          );
          if (rootNew != null) rootNew = rootNew! - 1;
        }
      }
    }
  }

  return QueueAdmissionResult(
    dayLearning: List.unmodifiable(admittedDayLearning),
    reviews: List.unmodifiable(admittedReviews),
    newCards: List.unmodifiable(admittedNew),
  );
}

bool _deckOrParentLimitReached<DeckIdT>(
  DeckIdT deckId,
  Map<DeckIdT, int?> limits,
  Map<DeckIdT, DeckIdT?> parents,
  DeckIdT rootDeckId,
) {
  DeckIdT? current = deckId;
  final visited = <DeckIdT>{};
  while (current != null && current != rootDeckId && visited.add(current)) {
    if (limits[current] == 0) return true;
    current = parents[current];
  }
  return false;
}

void _decrementDeckAndParents<DeckIdT>(
  DeckIdT deckId,
  Map<DeckIdT, int?> limits,
  Map<DeckIdT, DeckIdT?> parents,
  DeckIdT rootDeckId,
) {
  DeckIdT? current = deckId;
  final visited = <DeckIdT>{};
  while (current != null && current != rootDeckId && visited.add(current)) {
    final remaining = limits[current];
    if (remaining != null && remaining > 0) limits[current] = remaining - 1;
    current = parents[current];
  }
}

void _decrementReviewAndParents<DeckIdT>(
  DeckIdT deckId,
  Map<DeckIdT, int?> remainingReview,
  Map<DeckIdT, int?> remainingNew,
  Map<DeckIdT, DeckIdT?> parents,
  DeckIdT rootDeckId, {
  required bool capNewToReview,
}) {
  DeckIdT? current = deckId;
  final visited = <DeckIdT>{};
  while (current != null && current != rootDeckId && visited.add(current)) {
    final review = remainingReview[current];
    if (review != null && review > 0) {
      remainingReview[current] = review - 1;
      if (capNewToReview) {
        remainingNew[current] = _minLimit(remainingNew[current], review - 1);
      }
    }
    current = parents[current];
  }
}

int? _minLimit(int? one, int? two) {
  if (one == null) return two;
  if (two == null) return one;
  return one < two ? one : two;
}
