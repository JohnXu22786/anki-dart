/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';

/// One card prepared for the shared Card Browser preview surface.
final class CardBrowserPreviewCard {
  const CardBrowserPreviewCard({
    required this.id,
    required this.questionHtml,
    required this.answerHtml,
  });

  final BigInt id;
  final String questionHtml;
  final String answerHtml;
}

/// A preview payload in source query order and its source-derived starting row.
final class CardBrowserPreviewSession {
  CardBrowserPreviewSession({
    required List<CardBrowserPreviewCard> cards,
    required this.currentIndex,
  }) : cards = List.unmodifiable(cards);

  final List<CardBrowserPreviewCard> cards;
  final int currentIndex;
}

/// Collection-backed screen navigation boundary for Card Browser preview.
abstract interface class CardBrowserPreviewController {
  Future<CardBrowserPreviewSession> loadPreview({
    required List<BrowserRowId> selectedRows,
  });
}

/// Injectable loader used by [CardBrowserPreviewController] implementations.
abstract interface class CardBrowserPreviewLoader {
  Future<CardBrowserPreviewSession> load({
    required BrowserColumnMode mode,
    required List<BrowserRowId> rowIds,
    required List<BrowserRowId> selectedRows,
  });
}

/// Builds source-ordered exact card IDs for the two Card Browser modes.
BrowserPreviewPayloadBigInt cardBrowserPreviewPayload({
  required BrowserColumnMode mode,
  required List<BrowserRowId> rowIds,
  required List<BrowserRowId> selectedRows,
  required Map<String, List<BigInt>> cardsByNoteId,
}) {
  final oneCardPerRowIds = mode == BrowserColumnMode.cards
      ? [for (final row in rowIds) row.bigValue]
      : [
          for (final row in rowIds)
            if (cardsByNoteId[row.bigValue.toString()] case [final card, ...])
              card,
        ];
  final selectedCardIds = mode == BrowserColumnMode.cards
      ? [for (final row in selectedRows) row.bigValue]
      : [
          for (final row in selectedRows)
            ...(cardsByNoteId[row.bigValue.toString()] ?? const <BigInt>[]),
        ];
  return browserPreviewPayloadBigInt(
    rowIds: rowIds,
    selectedRows: selectedRows,
    oneCardPerRowIds: oneCardPerRowIds,
    selectedCardIds: selectedCardIds,
  );
}
