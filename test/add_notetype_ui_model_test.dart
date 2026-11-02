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
 * Behavioral reference: NotetypeUiModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AddNotetypeUiModel', () {
    test('uses false for isStandard when omitted', () {
      final model = AddNotetypeUiModel(id: 42, name: 'Basic');

      expect(model.id, 42);
      expect(model.name, 'Basic');
      expect(model.isStandard, isFalse);
    });

    test('uses all fields for structural equality and hashing', () {
      final model = AddNotetypeUiModel(id: 42, name: 'Basic', isStandard: true);
      final equalModel = AddNotetypeUiModel(
        id: 42,
        name: 'Basic',
        isStandard: true,
      );

      expect(model, equalModel);
      expect(model.hashCode, equalModel.hashCode);
      expect(model.hashCode, 1982677035);
      expect(
        AddNotetypeUiModel(
          id: 4294967297,
          name: 'Basic',
          isStandard: true,
        ).hashCode,
        AddNotetypeUiModel(id: 0, name: 'Basic', isStandard: true).hashCode,
      );
      expect(
        model,
        isNot(AddNotetypeUiModel(id: 43, name: 'Basic', isStandard: true)),
      );
      expect(
        model,
        isNot(AddNotetypeUiModel(id: 42, name: 'Cloze', isStandard: true)),
      );
      expect(model, isNot(AddNotetypeUiModel(id: 42, name: 'Basic')));
    });
  });

  test('maps host note-type id and name to a non-standard model', () {
    final model = addNotetypeUiModelFromNameId(id: 4294967297, name: 'Custom');

    expect(model, AddNotetypeUiModel(id: 4294967297, name: 'Custom'));
    expect(model.isStandard, isFalse);
  });
}
