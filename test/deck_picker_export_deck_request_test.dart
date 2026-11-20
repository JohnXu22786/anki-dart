/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Deck Picker export request case; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  test('format order and defaults match AnkiDroid export controls', () {
    expect(DeckPickerExportFormat.values, [
      DeckPickerExportFormat.collection,
      DeckPickerExportFormat.apkg,
      DeckPickerExportFormat.notes,
      DeckPickerExportFormat.cards,
    ]);

    final collection = DeckPickerExportOptions.defaultsFor(
      DeckPickerExportFormat.collection,
    );
    expect(collection.includeMedia, isTrue);
    expect(collection.includeLegacy, isFalse);
    expect(DeckPickerExportFormat.collection.visibleOptions, {
      DeckPickerExportOption.includeMedia,
      DeckPickerExportOption.includeLegacy,
    });

    final apkg = DeckPickerExportOptions.defaultsFor(
      DeckPickerExportFormat.apkg,
    );
    expect(apkg.includeScheduling, isTrue);
    expect(apkg.includeDeckConfigs, isFalse);
    expect(apkg.includeMedia, isTrue);
    expect(apkg.includeLegacy, isFalse);
    expect(DeckPickerExportFormat.apkg.visibleOptions, {
      DeckPickerExportOption.includeScheduling,
      DeckPickerExportOption.includeDeckConfigs,
      DeckPickerExportOption.includeMedia,
      DeckPickerExportOption.includeLegacy,
    });

    final notes = DeckPickerExportOptions.defaultsFor(
      DeckPickerExportFormat.notes,
    );
    expect(notes.includeHtml, isTrue);
    expect(notes.includeTags, isTrue);
    expect(notes.includeDeckName, isFalse);
    expect(notes.includeNotetypeName, isFalse);
    expect(notes.includeGuid, isFalse);
    expect(DeckPickerExportFormat.notes.visibleOptions, {
      DeckPickerExportOption.includeHtml,
      DeckPickerExportOption.includeTags,
      DeckPickerExportOption.includeDeckName,
      DeckPickerExportOption.includeNotetypeName,
      DeckPickerExportOption.includeGuid,
    });

    final cards = DeckPickerExportOptions.defaultsFor(
      DeckPickerExportFormat.cards,
    );
    expect(cards.includeHtml, isTrue);
    expect(DeckPickerExportFormat.cards.visibleOptions, {
      DeckPickerExportOption.includeHtml,
    });
  });

  test('export request carries format options and exact 64-bit deck ID', () {
    final deckId = Int64.parseInt('9007199254740995');
    final options = DeckPickerExportOptions.defaultsFor(
      DeckPickerExportFormat.apkg,
    ).copyWith(includeDeckConfigs: true);

    final request = projectDeckPickerExportDeck(
      exactDeckId: deckId,
      legacyDeckId: 17,
      format: DeckPickerExportFormat.apkg,
      options: options,
    );

    expect(request.deckId, deckId);
    expect(request.format, DeckPickerExportFormat.apkg);
    expect(request.includeScheduling, isTrue);
    expect(request.includeDeckConfigs, isTrue);
    expect(request.includeMedia, isTrue);
  });

  test('export request uses legacy int only when exact ID is absent', () {
    final request = projectDeckPickerExportDeck(legacyDeckId: -17);

    expect(request.deckId, Int64(-17));
  });

  test('all decks projects to an unrestricted deck limit', () {
    final request = projectDeckPickerExportDeck(
      legacyDeckId: 0,
      allDecks: true,
      format: DeckPickerExportFormat.notes,
      options: DeckPickerExportOptions.defaultsFor(
        DeckPickerExportFormat.notes,
      ),
    );

    expect(request.deckId, isNull);
    expect(request.format, DeckPickerExportFormat.notes);
    expect(request.includeTags, isTrue);
  });
}
