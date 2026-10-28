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
 * Source-derived from DeckPickerViewModel.kt:413–428 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Deck Picker scheduler upgrade prompt', () {
    test(
      'prompts for legacy version when the shown version is null or old',
      () {
        final missingShownVersion = projectDeckPickerSchedulerUpgradePrompt(
          schedulerVersion: 1,
          schedulerUpgradeDialogShownForVersion: null,
        );
        expect(missingShownVersion.shouldShowPrompt, isTrue);
        expect(
          missingShownVersion.nextSchedulerUpgradeDialogShownForVersion,
          1,
        );

        final olderShownVersion = projectDeckPickerSchedulerUpgradePrompt(
          schedulerVersion: 1,
          schedulerUpgradeDialogShownForVersion: 0,
        );
        expect(olderShownVersion.shouldShowPrompt, isTrue);
        expect(olderShownVersion.nextSchedulerUpgradeDialogShownForVersion, 1);
      },
    );

    test('does not repeat the prompt after legacy version 1 was shown', () {
      final result = projectDeckPickerSchedulerUpgradePrompt(
        schedulerVersion: 1,
        schedulerUpgradeDialogShownForVersion: 1,
      );

      expect(result.shouldShowPrompt, isFalse);
      expect(result.nextSchedulerUpgradeDialogShownForVersion, 1);
    });

    test('stores a non-legacy version without prompting', () {
      final result = projectDeckPickerSchedulerUpgradePrompt(
        schedulerVersion: 2,
        schedulerUpgradeDialogShownForVersion: null,
      );

      expect(result.shouldShowPrompt, isFalse);
      expect(result.nextSchedulerUpgradeDialogShownForVersion, 2);

      final oldShownVersion = projectDeckPickerSchedulerUpgradePrompt(
        schedulerVersion: 2,
        schedulerUpgradeDialogShownForVersion: 1,
      );
      expect(oldShownVersion.shouldShowPrompt, isFalse);
      expect(oldShownVersion.nextSchedulerUpgradeDialogShownForVersion, 2);
    });

    test(
      'falls back to legacy version 1 for missing or wrongly typed config',
      () {
        final result = projectDeckPickerSchedulerUpgradePrompt(
          schedulerVersion: null,
          schedulerUpgradeDialogShownForVersion: null,
        );

        expect(result.currentSchedulerVersion, 1);
        expect(result.shouldShowPrompt, isTrue);
        expect(result.nextSchedulerUpgradeDialogShownForVersion, 1);
      },
    );
  });
}
