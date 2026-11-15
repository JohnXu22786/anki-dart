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
 * Source-derived Check Pronunciation playback-routing cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Check Pronunciation playback plan', () {
    test('hidden playback UI produces no effects', () {
      final effects = planCheckPronunciationPlayback(
        isPlaybackVisible: false,
        isPlayerPlaying: true,
        isPlayerPaused: false,
        currentFileAbsolutePath: '/tmp/recording.3gp',
      );

      expect(effects, isEmpty);
    });

    test('playing requests replay, progress update, then replay event', () {
      final effects = planCheckPronunciationPlayback(
        isPlaybackVisible: true,
        isPlayerPlaying: true,
        isPlayerPaused: true,
        currentFileAbsolutePath: '/tmp/recording.3gp',
      );

      expect(effects.map((effect) => effect.runtimeType), [
        CheckPronunciationReplayEffect,
        CheckPronunciationProgressJobEffect,
        CheckPronunciationReplayEventEffect,
      ]);
    });

    test(
      'paused publishes playing, resumes, then requests progress update',
      () {
        final effects = planCheckPronunciationPlayback(
          isPlaybackVisible: true,
          isPlayerPlaying: false,
          isPlayerPaused: true,
          currentFileAbsolutePath: '/tmp/recording.3gp',
        );

        expect(effects.map((effect) => effect.runtimeType), [
          CheckPronunciationPlayingStateEffect,
          CheckPronunciationResumeEffect,
          CheckPronunciationProgressJobEffect,
        ]);
        expect(
          (effects.first as CheckPronunciationPlayingStateEffect).isPlaying,
          isTrue,
        );
      },
    );

    test(
      'stopped publishes playing before playing the exact supplied path',
      () {
        const path = '/host/absolute path/recording.3gp';
        final effects = planCheckPronunciationPlayback(
          isPlaybackVisible: true,
          isPlayerPlaying: false,
          isPlayerPaused: false,
          currentFileAbsolutePath: path,
        );

        expect(effects.map((effect) => effect.runtimeType), [
          CheckPronunciationPlayingStateEffect,
          CheckPronunciationPlayEffect,
        ]);
        expect(
          (effects.first as CheckPronunciationPlayingStateEffect).isPlaying,
          isTrue,
        );
        expect(
          (effects.last as CheckPronunciationPlayEffect).absolutePath,
          path,
        );
      },
    );

    test(
      'stopped with null path still publishes playing without a play effect',
      () {
        final effects = planCheckPronunciationPlayback(
          isPlaybackVisible: true,
          isPlayerPlaying: false,
          isPlayerPaused: false,
          currentFileAbsolutePath: null,
        );

        expect(effects, hasLength(1));
        expect(effects.single, isA<CheckPronunciationPlayingStateEffect>());
        expect(
          (effects.single as CheckPronunciationPlayingStateEffect).isPlaying,
          isTrue,
        );
      },
    );
  });
}
