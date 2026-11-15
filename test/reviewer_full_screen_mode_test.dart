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
 * Behavioral reference: FullScreenMode.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer full-screen mode', () {
    test('preserves enum preference strings, default, and predicate', () {
      expect(ReviewerFullScreenMode.values, const [
        ReviewerFullScreenMode.buttonsAndMenu,
        ReviewerFullScreenMode.buttonsOnly,
        ReviewerFullScreenMode.fullscreenAllGone,
      ]);
      expect(
        ReviewerFullScreenMode.defaultMode,
        ReviewerFullScreenMode.buttonsAndMenu,
      );
      expect(ReviewerFullScreenMode.buttonsAndMenu.getPreferenceValue(), '0');
      expect(ReviewerFullScreenMode.buttonsOnly.getPreferenceValue(), '1');
      expect(
        ReviewerFullScreenMode.fullscreenAllGone.getPreferenceValue(),
        '2',
      );
      expect(
        ReviewerFullScreenMode.buttonsAndMenu.isFullScreenReview(),
        isFalse,
      );
      expect(ReviewerFullScreenMode.buttonsOnly.isFullScreenReview(), isTrue);
      expect(
        ReviewerFullScreenMode.fullscreenAllGone.isFullScreenReview(),
        isTrue,
      );
    });

    test(
      'missing, null, recognized, and unknown values resolve source default',
      () {
        const missing = <String, String?>{};
        expect(
          ReviewerFullScreenMode.fromPreference(missing['fullscreenMode']),
          ReviewerFullScreenMode.buttonsAndMenu,
        );
        expect(
          ReviewerFullScreenMode.fromPreference(null),
          ReviewerFullScreenMode.buttonsAndMenu,
        );
        expect(
          ReviewerFullScreenMode.fromPreference('0'),
          ReviewerFullScreenMode.buttonsAndMenu,
        );
        expect(
          ReviewerFullScreenMode.fromPreference('1'),
          ReviewerFullScreenMode.buttonsOnly,
        );
        expect(
          ReviewerFullScreenMode.fromPreference('2'),
          ReviewerFullScreenMode.fullscreenAllGone,
        );
        expect(
          ReviewerFullScreenMode.fromPreference('unexpected'),
          ReviewerFullScreenMode.buttonsAndMenu,
        );
        expect(isFullScreenReview('unexpected'), isFalse);
      },
    );

    test(
      'legacy upgrade skips absent key and preserves source write order',
      () {
        expect(
          planReviewerFullScreenLegacyUpgrade(
            containsLegacyPreference: false,
            legacyValue: true,
          ),
          isNull,
        );

        final enabled = planReviewerFullScreenLegacyUpgrade(
          containsLegacyPreference: true,
          legacyValue: true,
        );
        expect(enabled?.writes, const [
          ReviewerFullScreenPreferenceWrite(key: 'fullscreenMode', value: '1'),
          ReviewerFullScreenPreferenceRemoval(key: 'fullscreenReview'),
        ]);

        final disabled = planReviewerFullScreenLegacyUpgrade(
          containsLegacyPreference: true,
          legacyValue: false,
        );
        expect(disabled?.writes, const [
          ReviewerFullScreenPreferenceWrite(key: 'fullscreenMode', value: '0'),
          ReviewerFullScreenPreferenceRemoval(key: 'fullscreenReview'),
        ]);
      },
    );

    test('set preference plans only the selected mode string write', () {
      expect(
        planReviewerFullScreenPreference(
          ReviewerFullScreenMode.fullscreenAllGone,
        ).writes,
        const [
          ReviewerFullScreenPreferenceWrite(key: 'fullscreenMode', value: '2'),
        ],
      );
    });
  });
}
