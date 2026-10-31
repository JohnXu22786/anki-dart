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
 * Source-derived cases for InstantEditorViewModel cloze helpers;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Instant Editor cloze state', () {
    test(
      'field text replaces ordinals in source order and keeps duplicates',
      () {
        final state = InstantEditorClozeState();

        state.setClozeFieldText('{{c2::two}} {{c1::one}} {{c2::again}}');

        expect(
          state.actualClozeFieldText,
          '{{c2::two}} {{c1::one}} {{c2::again}}',
        );
        expect(state.clozeOrdinals, [2, 1, 2]);
        expect(state.clozeDeletionCount, 3);
        expect(state.currentClozeNumber, 3);
      },
    );

    test('nullable and out-of-range field ordinals follow Kotlin parsing', () {
      final state = InstantEditorClozeState();
      state.setClozeFieldText('{{c2147483648::large}} {{c3::three}}');
      expect(state.clozeOrdinals, [3]);
      expect(state.currentClozeNumber, 4);

      state.setClozeFieldText(null);
      expect(state.actualClozeFieldText, isNull);
      expect(state.clozeOrdinals, isEmpty);
      expect(state.currentClozeNumber, 1);

      state.setClozeFieldText('{{c2147483647::max}}');
      expect(state.currentClozeNumber, -2147483648);
    });

    test(
      'no-increment field updates choose max ordinal and mode toggles adjust',
      () {
        final state = InstantEditorClozeState();
        state.setClozeFieldText('{{c1::one}} {{c3::three}}');
        expect(state.currentClozeNumber, 4);

        state.toggleClozeMode();
        expect(state.currentClozeMode, ClozeNumberMode.noIncrement);
        expect(state.currentClozeNumber, 3);
        state.setClozeFieldText('{{c2::two}} {{c2::again}}');
        expect(state.currentClozeNumber, 2);
        state.toggleClozeMode();
        expect(state.currentClozeMode, ClozeNumberMode.increment);
        expect(state.currentClozeNumber, 3);
      },
    );

    test('empty mode toggles do not adjust the counter', () {
      final state = InstantEditorClozeState();

      state.toggleClozeMode();
      expect(state.currentClozeNumber, 1);
      state.toggleClozeMode();
      expect(state.currentClozeNumber, 1);
    });

    test('build wraps source word and preserves start and end punctuation', () {
      final state = InstantEditorClozeState();

      expect(state.buildClozeText('!?hello-world!'), '!?{{c1::hello-world}}!');
      expect(state.currentClozeNumber, 2);
      expect(state.clozeOrdinals, [1]);
    });

    test('build preserves source null interpolation for unmatched input', () {
      final state = InstantEditorClozeState();

      expect(state.buildClozeText('!!!'), 'null{{c1::null}}null');
      expect(state.currentClozeNumber, 2);
      expect(state.clozeOrdinals, [1]);
    });

    test('removal updates counter and duplicate list in source order', () {
      final state = InstantEditorClozeState();
      state.setClozeFieldText('{{c1::first}} {{c2::second}} {{c3::third}}');

      expect(state.buildClozeText('{{c2::second}}'), 'second');
      expect(state.clozeOrdinals, [1, 3]);
      expect(state.currentClozeNumber, 4);
      expect(state.buildClozeText('{{c3::third}}'), 'third');
      expect(state.currentClozeNumber, 2);
    });

    test(
      'no-increment builds reuse counter and reset only after last removal',
      () {
        final state = InstantEditorClozeState();
        state.toggleClozeMode();

        expect(state.buildClozeText('first'), '{{c1::first}}');
        expect(state.buildClozeText('second'), '{{c1::second}}');
        expect(state.currentClozeNumber, 1);
        expect(state.clozeOrdinals, [1, 1]);
        state.buildClozeText('{{c1::first}}');
        expect(state.clozeOrdinals, [1]);
        expect(state.currentClozeNumber, 1);
        state.buildClozeText('{{c1::second}}');
        expect(state.clozeOrdinals, isEmpty);
        expect(state.currentClozeNumber, 1);
      },
    );

    test('cloze conversion throws on source Int.toInt overflow', () {
      final state = InstantEditorClozeState();
      expect(
        () => state.buildClozeText('{{c2147483648::too large}}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
