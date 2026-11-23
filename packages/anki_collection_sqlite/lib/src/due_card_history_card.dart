// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart'
    show CardId, DeckId, NoteId;

/// The collection fields Core uses as input to load-balancer history.
final class DueCardHistoryCard {
  const DueCardHistoryCard({
    required this.id,
    required this.noteId,
    required this.deckId,
    required this.dueDay,
  });

  final CardId id;
  final NoteId noteId;
  final DeckId deckId;
  final int dueDay;
}
