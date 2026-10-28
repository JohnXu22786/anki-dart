/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardBrowserViewModel.kt; pinned tests cover preview
 * samples and active-column round trips, not this pure list projection.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

enum _Column { question, deck, tags, answer }

final class _Sample {
  const _Sample(this.column, this.value);

  final _Column column;
  final String value;
}

void main() {
  group('Browser preview column ordering', () {
    test(
      'orders displayed samples by first current-column index and keeps stable ties',
      () {
        final questionFirst = _Sample(_Column.question, 'question first');
        final deckFirst = _Sample(_Column.deck, 'deck first');
        final unavailable = _Sample(_Column.tags, 'unavailable');
        final deckSecond = _Sample(_Column.deck, 'deck second');
        final questionSecond = _Sample(_Column.question, 'question second');
        final samples = [
          questionFirst,
          deckFirst,
          unavailable,
          deckSecond,
          questionSecond,
        ];
        final currentColumns = [_Column.deck, _Column.question, _Column.deck];

        final projection = projectBrowserPreviewColumns(
          samples: samples,
          currentColumns: currentColumns,
          columnTypeOf: (sample) => sample.column,
        );

        expect(projection.displayed, [
          same(deckFirst),
          same(deckSecond),
          same(questionFirst),
          same(questionSecond),
        ]);
        expect(projection.available, [same(unavailable)]);
        expect(samples, [
          same(questionFirst),
          same(deckFirst),
          same(unavailable),
          same(deckSecond),
          same(questionSecond),
        ]);
        expect(currentColumns, [_Column.deck, _Column.question, _Column.deck]);
      },
    );

    test(
      'preserves sample order and identity when all columns are available',
      () {
        final first = _Sample(_Column.tags, 'first');
        final second = _Sample(_Column.answer, 'second');
        final samples = [first, second];

        final projection = projectBrowserPreviewColumns(
          samples: samples,
          currentColumns: const <_Column>[],
          columnTypeOf: (sample) => sample.column,
        );

        expect(projection.displayed, isEmpty);
        expect(projection.available, [same(first), same(second)]);
        expect(samples, [same(first), same(second)]);
      },
    );

    test('returns two empty lists when there are no samples', () {
      final projection = projectBrowserPreviewColumns(
        samples: const <_Sample>[],
        currentColumns: const [_Column.deck, _Column.question],
        columnTypeOf: (sample) => sample.column,
      );

      expect(projection.displayed, isEmpty);
      expect(projection.available, isEmpty);
    });
  });
}
