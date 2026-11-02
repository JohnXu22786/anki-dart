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
 *
 * Behavioral reference: ChangeNoteTypeViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectChangeNoteTypeDiscardedFields', () {
    test('empty fields produce an empty list regardless of mappings', () {
      expect(
        projectChangeNoteTypeDiscardedFields(
          inputFieldNames: const [],
          fieldMap: {0: 0, 1: null},
        ),
        isEmpty,
      );
    });

    test('empty mapping keeps names in order, including repeated names', () {
      expect(
        projectChangeNoteTypeDiscardedFields(
          inputFieldNames: const ['Front', 'Front', 'Back'],
          fieldMap: const {},
        ),
        ['Front', 'Front', 'Back'],
      );
    });

    test(
      'duplicate mapped indices do not deduplicate remaining field names',
      () {
        expect(
          projectChangeNoteTypeDiscardedFields(
            inputFieldNames: const ['Front', 'Front', 'Back', 'Front'],
            fieldMap: {0: 1, 1: 1, 2: 3},
          ),
          ['Front', 'Back'],
        );
      },
    );

    test('null mapped indices do not match integer list indices', () {
      expect(
        projectChangeNoteTypeDiscardedFields(
          inputFieldNames: const ['Front', 'Back'],
          fieldMap: {0: null, 1: null},
        ),
        ['Front', 'Back'],
      );
    });

    test('out-of-range mapped indices do not remove or normalize fields', () {
      expect(
        projectChangeNoteTypeDiscardedFields(
          inputFieldNames: const ['Front', 'Back'],
          fieldMap: {0: -1, 1: 8},
        ),
        ['Front', 'Back'],
      );
    });
  });
}
