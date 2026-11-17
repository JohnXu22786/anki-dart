/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_dart/anki_dart.dart';

import 'card_browser_screen.dart';

/// Core-sourced row-level font, direction, color, and elision attributes.
final class BrowserRowMetadata {
  BrowserRowMetadata({
    required this.fontName,
    required this.fontSize,
    required this.color,
    required Map<String, bool> rtlCells,
    required Map<String, CardBrowserElideMode> elideModes,
  }) : rtlCells = Map.unmodifiable(rtlCells),
       elideModes = Map.unmodifiable(elideModes);

  final String fontName;
  final int fontSize;
  final CardBrowserRowColor color;
  final Map<String, bool> rtlCells;
  final Map<String, CardBrowserElideMode> elideModes;
}

BrowserRowMetadata browserRowMetadata({
  required BrowserColumnMode mode,
  required models.Note note,
  required models.Notetype notetype,
  required models.Card? card,
  required List<BrowserColumn> columns,
}) {
  final templateIndex = card?.templateIdx ?? -1;
  final template =
      templateIndex >= 0 && templateIndex < notetype.templates.length
      ? notetype.templates[templateIndex]
      : null;
  final fieldIndex = notetype.config.sortFieldIdx;
  final marked = note.tags.any((tag) => tag.toLowerCase() == 'marked');
  final color = mode == BrowserColumnMode.notes || card == null
      ? marked
            ? CardBrowserRowColor.marked
            : CardBrowserRowColor.defaultColor
      : _cardColor(card, marked);
  return BrowserRowMetadata(
    fontName: template?.config.browserFontName ?? '',
    fontSize: template?.config.browserFontSize ?? 0,
    color: color,
    rtlCells: {
      if (fieldIndex >= 0 && fieldIndex < notetype.fields.length)
        BrowserColumn.sortField.key: notetype.fields[fieldIndex].config.rtl,
    },
    elideModes: {
      for (final column in columns)
        column.key: column == BrowserColumn.deck
            ? CardBrowserElideMode.middle
            : CardBrowserElideMode.right,
    },
  );
}

CardBrowserRowColor _cardColor(models.Card card, bool marked) {
  if (card.flags >= 1 && card.flags <= 7) {
    return CardBrowserRowColor.values[CardBrowserRowColor.flagRed.index +
        card.flags -
        1];
  }
  if (marked) return CardBrowserRowColor.marked;
  return switch (card.queue) {
    models.CardQueue.suspended => CardBrowserRowColor.suspended,
    models.CardQueue.schedBuried ||
    models.CardQueue.userBuried => CardBrowserRowColor.buried,
    _ => CardBrowserRowColor.defaultColor,
  };
}
