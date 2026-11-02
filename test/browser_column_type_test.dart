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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserColumn type projection', () {
    test('maps every column type in Cards mode', () {
      const expected = <BrowserColumn, BrowserColumnType>{
        BrowserColumn.question: BrowserColumnType.text,
        BrowserColumn.answer: BrowserColumnType.text,
        BrowserColumn.sortField: BrowserColumnType.text,
        BrowserColumn.deck: BrowserColumnType.text,
        BrowserColumn.tags: BrowserColumnType.text,
        BrowserColumn.cardType: BrowserColumnType.text,
        BrowserColumn.due: BrowserColumnType.unspecified,
        BrowserColumn.ease: BrowserColumnType.numeric,
        BrowserColumn.changed: BrowserColumnType.date,
        BrowserColumn.created: BrowserColumnType.date,
        BrowserColumn.edited: BrowserColumnType.date,
        BrowserColumn.interval: BrowserColumnType.numeric,
        BrowserColumn.lapses: BrowserColumnType.numeric,
        BrowserColumn.noteType: BrowserColumnType.text,
        BrowserColumn.reviews: BrowserColumnType.numeric,
        BrowserColumn.fsrsDifficulty: BrowserColumnType.numeric,
        BrowserColumn.fsrsRetrievability: BrowserColumnType.numeric,
        BrowserColumn.fsrsStability: BrowserColumnType.numeric,
        BrowserColumn.originalPosition: BrowserColumnType.numeric,
      };

      expect(BrowserColumn.values, hasLength(expected.length));
      for (final column in BrowserColumn.values) {
        expect(
          column.typeFor(BrowserColumnMode.cards),
          expected[column],
          reason: column.key,
        );
      }
    });

    test('maps every column type in Notes mode', () {
      const expected = <BrowserColumn, BrowserColumnType>{
        BrowserColumn.question: BrowserColumnType.text,
        BrowserColumn.answer: BrowserColumnType.text,
        BrowserColumn.sortField: BrowserColumnType.text,
        BrowserColumn.deck: BrowserColumnType.text,
        BrowserColumn.tags: BrowserColumnType.text,
        BrowserColumn.cardType: BrowserColumnType.numeric,
        BrowserColumn.due: BrowserColumnType.unspecified,
        BrowserColumn.ease: BrowserColumnType.numeric,
        BrowserColumn.changed: BrowserColumnType.date,
        BrowserColumn.created: BrowserColumnType.date,
        BrowserColumn.edited: BrowserColumnType.date,
        BrowserColumn.interval: BrowserColumnType.numeric,
        BrowserColumn.lapses: BrowserColumnType.numeric,
        BrowserColumn.noteType: BrowserColumnType.text,
        BrowserColumn.reviews: BrowserColumnType.numeric,
        BrowserColumn.fsrsDifficulty: BrowserColumnType.numeric,
        BrowserColumn.fsrsRetrievability: BrowserColumnType.numeric,
        BrowserColumn.fsrsStability: BrowserColumnType.numeric,
        BrowserColumn.originalPosition: BrowserColumnType.numeric,
      };

      expect(BrowserColumn.values, hasLength(expected.length));
      for (final column in BrowserColumn.values) {
        expect(
          column.typeFor(BrowserColumnMode.notes),
          expected[column],
          reason: column.key,
        );
      }
    });

    test('resolves the exact source column key and rejects unknown keys', () {
      expect(
        BrowserColumn.fromColumnKey('template')
            .typeFor(BrowserColumnMode.notes),
        BrowserColumnType.numeric,
      );
      expect(
        () => BrowserColumn.fromColumnKey('Template'),
        throwsArgumentError,
      );
    });
  });
}
