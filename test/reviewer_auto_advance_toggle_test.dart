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
 * Source-derived Reviewer Auto Advance toggle effect cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer Auto Advance toggle plan', () {
    test(
      'enabling publishes state and feedback before question scheduling',
      () {
        final effects = planReviewerAutoAdvanceToggle(
          wasEnabled: false,
          activatedMessage: 'Auto Advance activated',
          deactivatedMessage: 'Auto Advance deactivated',
          shouldWaitForAudio: false,
          isPlaying: false,
          showingAnswer: false,
        );

        _expectCoreOrder(
          effects,
          enabled: true,
          message: 'Auto Advance activated',
        );
        expect(effects.last, isA<RequestAutoAdvanceScheduleEffect>());
        expect(
          (effects.last as RequestAutoAdvanceScheduleEffect).side,
          ReviewerAutoAdvanceSide.question,
        );
      },
    );

    test('disabling still requests scheduling for the shown answer side', () {
      final effects = planReviewerAutoAdvanceToggle(
        wasEnabled: true,
        activatedMessage: 'Auto Advance activated',
        deactivatedMessage: 'Auto Advance deactivated',
        shouldWaitForAudio: false,
        isPlaying: false,
        showingAnswer: true,
      );

      _expectCoreOrder(
        effects,
        enabled: false,
        message: 'Auto Advance deactivated',
      );
      expect(effects.last, isA<RequestAutoAdvanceScheduleEffect>());
      expect(
        (effects.last as RequestAutoAdvanceScheduleEffect).side,
        ReviewerAutoAdvanceSide.answer,
      );
    });

    test('waiting while audio plays stops after feedback', () {
      final effects = planReviewerAutoAdvanceToggle(
        wasEnabled: false,
        activatedMessage: 'on',
        deactivatedMessage: 'off',
        shouldWaitForAudio: true,
        isPlaying: true,
        showingAnswer: false,
      );

      _expectCoreOrder(effects, enabled: true, message: 'on');
      expect(effects, hasLength(3));
    });

    test('waiting without playback still schedules the shown side', () {
      final effects = planReviewerAutoAdvanceToggle(
        wasEnabled: false,
        activatedMessage: 'on',
        deactivatedMessage: 'off',
        shouldWaitForAudio: true,
        isPlaying: false,
        showingAnswer: true,
      );

      _expectCoreOrder(effects, enabled: true, message: 'on');
      expect(effects.last, isA<RequestAutoAdvanceScheduleEffect>());
      expect(
        (effects.last as RequestAutoAdvanceScheduleEffect).side,
        ReviewerAutoAdvanceSide.answer,
      );
    });
  });
}

void _expectCoreOrder(
  List<ReviewerAutoAdvanceToggleEffect> effects, {
  required bool enabled,
  required String message,
}) {
  expect(effects.length, greaterThanOrEqualTo(3));
  expect(effects.take(3).map((effect) => effect.runtimeType), [
    SetAutoAdvanceEnabledEffect,
    PublishAutoAdvanceEnabledEffect,
    PublishAutoAdvanceFeedbackEffect,
  ]);
  expect((effects[0] as SetAutoAdvanceEnabledEffect).enabled, enabled);
  expect((effects[1] as PublishAutoAdvanceEnabledEffect).enabled, enabled);
  expect((effects[2] as PublishAutoAdvanceFeedbackEffect).message, message);
}
