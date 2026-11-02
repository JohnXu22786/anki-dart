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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Reviewer leech feedback composition cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer leech feedback message', () {
    test('requests only the base text once when not suspended', () {
      final calls = <String>[];

      final message = reviewerLeechFeedbackMessage(
        isSuspended: false,
        studyingCardWasALeech: () {
          calls.add('leech');
          return '  leech message  ';
        },
        studyingItHasBeenSuspended: () {
          calls.add('suspended');
          return 'unused';
        },
      );

      expect(message, '  leech message  ');
      expect(calls, ['leech']);
    });

    test('requests both texts once in order and inserts one ASCII space', () {
      final calls = <String>[];

      final message = reviewerLeechFeedbackMessage(
        isSuspended: true,
        studyingCardWasALeech: () {
          calls.add('leech');
          return 'leech ';
        },
        studyingItHasBeenSuspended: () {
          calls.add('suspended');
          return ' suspended';
        },
      );

      expect(message, 'leech   suspended');
      expect(calls, ['leech', 'suspended']);
    });

    test('preserves the separator for empty localized texts', () {
      expect(
        reviewerLeechFeedbackMessage(
          isSuspended: true,
          studyingCardWasALeech: () => '',
          studyingItHasBeenSuspended: () => '',
        ),
        ' ',
      );
    });

    test(
      'propagates base callback failure without requesting suspended text',
      () {
        final error = StateError('base failed');
        final calls = <String>[];

        expect(
          () => reviewerLeechFeedbackMessage(
            isSuspended: true,
            studyingCardWasALeech: () {
              calls.add('leech');
              throw error;
            },
            studyingItHasBeenSuspended: () {
              calls.add('suspended');
              return 'suspended';
            },
          ),
          throwsA(same(error)),
        );
        expect(calls, ['leech']);
      },
    );

    test('propagates suspended callback failure after the base callback', () {
      final error = StateError('suspended failed');
      final calls = <String>[];

      expect(
        () => reviewerLeechFeedbackMessage(
          isSuspended: true,
          studyingCardWasALeech: () {
            calls.add('leech');
            return 'leech';
          },
          studyingItHasBeenSuspended: () {
            calls.add('suspended');
            throw error;
          },
        ),
        throwsA(same(error)),
      );
      expect(calls, ['leech', 'suspended']);
    });
  });
}
