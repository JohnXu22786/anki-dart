// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:fixnum/fixnum.dart';

/// Queue selected by Core's active-deck due-card gather.
enum DueCardKind { review, interdayLearning }

/// Core's configurable SQL ordering for review and interday-learning cards.
enum ReviewCardOrder {
  day,
  dayThenDeck,
  deckThenDay,
  intervalsAscending,
  intervalsDescending,
  easeAscending,
  easeDescending,
  retrievabilityAscending,
  random,
  added,
  reverseAdded,
  retrievabilityDescending,
  relativeOverdueness,
}

/// A due review or interday-learning card returned from the collection.
final class DueCardCandidate {
  const DueCardCandidate({
    required this.id,
    required this.noteId,
    required this.due,
    required this.interval,
    required this.mtimeSecs,
    required this.currentDeckId,
    required this.originalDeckId,
    required this.reps,
    required this.kind,
  });

  final Int64 id;
  final Int64 noteId;
  final int due;
  final Int64 interval;
  final Int64 mtimeSecs;
  final Int64 currentDeckId;
  final Int64 originalDeckId;
  final int reps;
  final DueCardKind kind;
}
