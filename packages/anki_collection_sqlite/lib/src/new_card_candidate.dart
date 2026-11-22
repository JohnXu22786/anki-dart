// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:fixnum/fixnum.dart';

/// Core's gather-time ordering for new cards in one deck.
enum NewCardCandidateSorting {
  lowestPosition,
  highestPosition,
  randomNotes,
  randomCards,
}

/// A stored new card and the fields Core reads while gathering candidates.
final class NewCardCandidate {
  const NewCardCandidate({
    required this.id,
    required this.noteId,
    required this.templateOrdinal,
    required this.mtimeSecs,
    required this.currentDeckId,
    required this.originalDeckId,
  });

  final Int64 id;
  final Int64 noteId;
  final int templateOrdinal;
  final Int64 mtimeSecs;
  final Int64 currentDeckId;
  final Int64 originalDeckId;
}
