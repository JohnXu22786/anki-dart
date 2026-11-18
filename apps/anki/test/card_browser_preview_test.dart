/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_app/card_browser_preview.dart';
import 'package:anki_dart/anki_dart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Card Browser preview payload', () {
    test('Cards mode preserves exact IDs and selected-row ordering', () {
      final large = BigInt.parse('9007199254740993');
      final rows = [
        BrowserRowId.bigInt(large),
        const BrowserRowId(20),
        const BrowserRowId(30),
      ];

      final payload = cardBrowserPreviewPayload(
        mode: BrowserColumnMode.cards,
        rowIds: rows,
        selectedRows: [rows[2], rows[0]],
        cardsByNoteId: const {},
      );

      expect(payload.cardIds, [BigInt.from(30), large]);
      expect(payload.currentIndex, 0);
    });

    test(
      'Notes mode maps selected notes to all their cards in selection order',
      () {
        const firstNote = BrowserRowId(11);
        const secondNote = BrowserRowId(22);
        final firstCards = [BigInt.from(101), BigInt.from(102)];
        final secondCards = [BigInt.from(201)];

        final payload = cardBrowserPreviewPayload(
          mode: BrowserColumnMode.notes,
          rowIds: const [firstNote, secondNote],
          selectedRows: const [secondNote, firstNote],
          cardsByNoteId: {'11': firstCards, '22': secondCards},
        );

        expect(payload.cardIds, [
          BigInt.from(201),
          BigInt.from(101),
          BigInt.from(102),
        ]);
        expect(payload.currentIndex, 0);
      },
    );

    test('single selected Note starts at row position but previews one card per row', () {
      final largeNote = BigInt.parse('9223372036854775806');
      final rows = [const BrowserRowId(11), BrowserRowId.bigInt(largeNote)];
      final payload = cardBrowserPreviewPayload(
        mode: BrowserColumnMode.notes,
        rowIds: rows,
        selectedRows: [rows.last],
        cardsByNoteId: {
          '11': [BigInt.from(101), BigInt.from(102)],
          largeNote.toString(): [BigInt.parse('9007199254740993')],
        },
      );

      expect(payload.cardIds, [
        BigInt.from(101),
        BigInt.parse('9007199254740993'),
      ]);
      expect(payload.currentIndex, 1);
    });
  });
}
