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
 * Source-derived from Consts.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiCardType', () {
    test('maps each known code to its canonical singleton', () {
      final known = <int, LibAnkiCardType>{
        0: LibAnkiCardType.newCard,
        1: LibAnkiCardType.learning,
        2: LibAnkiCardType.review,
        3: LibAnkiCardType.relearning,
      };

      for (final entry in known.entries) {
        final decoded = LibAnkiCardType.fromCode(entry.key);
        expect(decoded, same(entry.value));
        expect(decoded.code, entry.key);
      }

      expect(LibAnkiCardType.fromCode(0), equals(LibAnkiCardType.newCard));
      expect(LibAnkiCardType.fromCode(3), equals(LibAnkiCardType.relearning));
    });

    test('retains unknown codes and keeps Unknown instances distinct', () {
      for (final code in <int>[-100, 4, 1 << 60]) {
        final first = LibAnkiCardType.fromCode(code);
        final second = LibAnkiCardType.fromCode(code);

        expect(first, isA<LibAnkiCardTypeUnknown>());
        expect(first.code, code);
        expect(first, isNot(same(second)));
        expect(first, isNot(equals(second)));
        expect(<LibAnkiCardType>{first, second}, hasLength(2));
      }
    });
  });

  group('LibAnkiQueueType', () {
    test('maps each known code to its canonical singleton', () {
      final known = <int, LibAnkiQueueType>{
        -3: LibAnkiQueueType.manuallyBuried,
        -2: LibAnkiQueueType.siblingBuried,
        -1: LibAnkiQueueType.suspended,
        0: LibAnkiQueueType.newCard,
        1: LibAnkiQueueType.learning,
        2: LibAnkiQueueType.review,
        3: LibAnkiQueueType.dayLearnRelearn,
      };

      for (final entry in known.entries) {
        final decoded = LibAnkiQueueType.fromCode(entry.key);
        expect(decoded, same(entry.value));
        expect(decoded.code, entry.key);
      }

      expect(
        LibAnkiQueueType.fromCode(-3),
        equals(LibAnkiQueueType.manuallyBuried),
      );
      expect(LibAnkiQueueType.preview.code, 4);
    });

    test('retains unknown codes and keeps Unknown instances distinct', () {
      for (final code in <int>[-100, -4, 4, 5, 1 << 60]) {
        final first = LibAnkiQueueType.fromCode(code);
        final second = LibAnkiQueueType.fromCode(code);

        expect(first, isA<LibAnkiQueueTypeUnknown>());
        expect(first.code, code);
        expect(first, isNot(same(second)));
        expect(first, isNot(equals(second)));
        expect(<LibAnkiQueueType>{first, second}, hasLength(2));
      }
    });

    test('classifies known and unknown buried or suspended boundaries', () {
      for (final type in <LibAnkiQueueType>[
        LibAnkiQueueType.manuallyBuried,
        LibAnkiQueueType.siblingBuried,
        LibAnkiQueueType.suspended,
      ]) {
        expect(type.buriedOrSuspended(), isTrue);
      }

      for (final type in <LibAnkiQueueType>[
        LibAnkiQueueType.newCard,
        LibAnkiQueueType.learning,
        LibAnkiQueueType.review,
        LibAnkiQueueType.dayLearnRelearn,
        LibAnkiQueueType.preview,
      ]) {
        expect(type.buriedOrSuspended(), isFalse);
      }

      expect(LibAnkiQueueType.fromCode(-4).buriedOrSuspended(), isTrue);
      expect(LibAnkiQueueType.fromCode(-1 << 60).buriedOrSuspended(), isTrue);
      expect(LibAnkiQueueType.fromCode(5).buriedOrSuspended(), isFalse);
      expect(LibAnkiQueueType.fromCode(1 << 60).buriedOrSuspended(), isFalse);
    });
  });

  group('LibAnkiNoteTypeKind', () {
    test('maps known codes to canonical singletons and preserves unknowns', () {
      expect(LibAnkiNoteTypeKind.fromCode(0), same(LibAnkiNoteTypeKind.std));
      expect(LibAnkiNoteTypeKind.fromCode(1), same(LibAnkiNoteTypeKind.cloze));
      expect(LibAnkiNoteTypeKind.std.code, 0);
      expect(LibAnkiNoteTypeKind.cloze.code, 1);

      for (final code in <int>[-100, 2, 1 << 60]) {
        final first = LibAnkiNoteTypeKind.fromCode(code);
        final second = LibAnkiNoteTypeKind.fromCode(code);

        expect(first, isA<LibAnkiNoteTypeKindUnknown>());
        expect(first.code, code);
        expect(first, isNot(same(second)));
        expect(first, isNot(equals(second)));
        expect(<LibAnkiNoteTypeKind>{first, second}, hasLength(2));
      }
    });
  });

  test('LibAnkiConsts matches every public Consts value', () {
    expect(LibAnkiConsts.dynOldest, 0);
    expect(LibAnkiConsts.dynRandom, 1);
    expect(LibAnkiConsts.dynSmallInt, 2);
    expect(LibAnkiConsts.dynBigInt, 3);
    expect(LibAnkiConsts.dynLapses, 4);
    expect(LibAnkiConsts.dynAdded, 5);
    expect(LibAnkiConsts.dynDue, 6);
    expect(LibAnkiConsts.dynRevAdded, 7);
    expect(LibAnkiConsts.dynDuePriority, 8);
    expect(LibAnkiConsts.dynMaxSize, 99999);
    expect(LibAnkiConsts.startingFactor, 2500);
    expect(LibAnkiConsts.backendSchemaVersion, 18);
    expect(LibAnkiConsts.syncVer, 10);
    expect(LibAnkiConsts.leechSuspend, 0);
    expect(LibAnkiConsts.defaultDeckId, 1);
    expect(LibAnkiConsts.fieldSeparator, '\u001f');
    expect(LibAnkiConsts.fieldSeparator.codeUnitAt(0), 0x1f);
    expect(LibAnkiConsts.shortToastDuration, 2000);
  });
}
