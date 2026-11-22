// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:fixnum/fixnum.dart';

/// A stored learning card selected for the caller's active decks and cutoff.
final class IntradayLearningCandidate {
  const IntradayLearningCandidate({
    required this.id,
    required this.noteId,
    required this.due,
    required this.mtimeSecs,
    required this.currentDeckId,
    required this.originalDeckId,
    required this.reps,
  });

  final Int64 id;
  final Int64 noteId;
  final int due;
  final Int64 mtimeSecs;
  final Int64 currentDeckId;
  final Int64 originalDeckId;
  final int reps;
}
