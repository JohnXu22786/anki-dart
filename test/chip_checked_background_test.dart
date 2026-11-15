/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Chip.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('readChipHasCheckedBackground', () {
    test('reads checked once and returns its value unchanged', () {
      for (final checked in [false, true]) {
        var reads = 0;

        final result = readChipHasCheckedBackground(
          isChecked: () {
            reads++;
            return checked;
          },
        );

        expect(result, checked);
        expect(reads, 1);
      }
    });
  });

  group('setChipHasCheckedBackground', () {
    for (final value in [true, false]) {
      test('sets $value in the exact source order', () {
        final events = <(String, bool)>[];

        setChipHasCheckedBackground(
          value: value,
          setCheckable: (checkable) => events.add(('checkable', checkable)),
          setChecked: (checked) => events.add(('checked', checked)),
        );

        expect(events, [
          ('checkable', true),
          ('checked', value),
          ('checkable', false),
        ]);
      });
    }

    test('propagates callback failures and stops subsequent calls', () {
      for (final throwingCall in [0, 1, 2]) {
        final events = <String>[];
        final failure = StateError('callback $throwingCall failed');

        expect(
          () => setChipHasCheckedBackground(
            value: true,
            setCheckable: (checkable) {
              events.add('checkable:$checkable');
              if ((throwingCall == 0 && checkable) ||
                  (throwingCall == 2 && !checkable)) {
                throw failure;
              }
            },
            setChecked: (checked) {
              events.add('checked:$checked');
              if (throwingCall == 1) throw failure;
            },
          ),
          throwsA(same(failure)),
        );

        expect(events, switch (throwingCall) {
          0 => ['checkable:true'],
          1 => ['checkable:true', 'checked:true'],
          _ => ['checkable:true', 'checked:true', 'checkable:false'],
        });
      }
    });
  });
}
