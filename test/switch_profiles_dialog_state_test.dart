/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SwitchProfilesViewModel.kt and
 * SwitchProfilesViewModelTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Switch Profiles dialog state', () {
    test('starts with no profiles and the add dialog hidden', () {
      final state = SwitchProfilesDialogState();

      expect(state.profiles, isEmpty);
      expect(state.isAddProfileDialogVisible, isFalse);
    });

    test('show and dismiss update dialog visibility', () {
      final state = SwitchProfilesDialogState();

      state.showAddProfileDialog();
      expect(state.isAddProfileDialogVisible, isTrue);

      state.dismissAddProfileDialog();
      expect(state.isAddProfileDialogVisible, isFalse);
    });

    test('adding a valid name hides the dialog without creating a profile', () {
      final state = SwitchProfilesDialogState();
      state.showAddProfileDialog();

      state.addProfile('Work');

      expect(state.isAddProfileDialogVisible, isFalse);
      expect(state.profiles, isEmpty);
    });
  });
}
