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
 * Behavioral reference: MediaCheckViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Media Check result publication plan', () {
    test('selects checking-media progress', () {
      final plan = planMediaCheckResultPublication<Object>();

      expect(plan.progress, MediaCheckProgress.checkingMedia);
    });

    test('publishes the exact opaque result after the check returns', () {
      final plan = planMediaCheckResultPublication<Object>();
      final result = Object();
      Object? published;

      final returned = plan.checkAndPublish(
        checkMedia: () => result,
        publishResult: (value) => published = value,
      );

      expect(published, same(result));
      expect(returned, same(result));
    });

    test('does not publish when the backend check fails', () {
      final plan = planMediaCheckResultPublication<Object>();
      final error = StateError('media check failed');
      Object? published;

      expect(
        () => plan.checkAndPublish(
          checkMedia: () => throw error,
          publishResult: (value) => published = value,
        ),
        throwsA(same(error)),
      );
      expect(published, isNull);
    });
  });
}
