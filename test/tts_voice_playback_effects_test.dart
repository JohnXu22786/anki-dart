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
 * Source-derived cases for TtsVoicesViewModel.playVoice() and playTts().
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TTS voice playback effects', () {
    test(
      'unavailable voice notification precedes playback with exact inputs',
      () {
        final voice = Object();
        const text = 'keep exact text';

        final effects = planTtsVoicePlayback(
          engineStatus: const TtsEngineSuccess(),
          voice: voice,
          textToSpeak: text,
          isUnavailable: true,
        );

        expect(effects, hasLength(2));
        expect(effects[0], isA<NotifyUnavailableTtsVoiceEffect<Object>>());
        expect(effects[1], isA<PlayTtsVoiceEffect<Object>>());
        expect(
          (effects[0] as NotifyUnavailableTtsVoiceEffect<Object>).voice,
          same(voice),
        );
        final play = effects[1] as PlayTtsVoiceEffect<Object>;
        expect(play.voice, same(voice));
        expect(play.textToSpeak, text);
      },
    );

    test('unavailable notification remains when engine is not ready', () {
      final voice = Object();

      final effects = planTtsVoicePlayback(
        engineStatus: const TtsEngineLoading(),
        voice: voice,
        textToSpeak: 'preview',
        isUnavailable: true,
      );

      expect(effects, hasLength(1));
      expect(effects.single, isA<NotifyUnavailableTtsVoiceEffect<Object>>());
      expect(
        (effects.single as NotifyUnavailableTtsVoiceEffect<Object>).voice,
        same(voice),
      );
    });

    test(
      'available voice has no notice, and non-ready engine has no playback',
      () {
        expect(
          planTtsVoicePlayback(
            engineStatus: const TtsEngineSuccess(),
            voice: Object(),
            textToSpeak: 'preview',
            isUnavailable: false,
          ),
          hasLength(1),
        );
        final engineError = TtsEngineError(Exception('engine'));
        expect(
          planTtsVoicePlayback(
            engineStatus: engineError,
            voice: Object(),
            textToSpeak: 'preview',
            isUnavailable: false,
          ),
          isEmpty,
        );
      },
    );

    test(
      'returned playback errors retain identity and null emits no effect',
      () {
        final error = Object();
        final effect = projectTtsPlaybackError(error);

        expect(effect, isA<EmitTtsPlaybackErrorEffect<Object>>());
        expect(
          (effect as EmitTtsPlaybackErrorEffect<Object>).error,
          same(error),
        );
        expect(projectTtsPlaybackError<Object>(null), isNull);
      },
    );
  });
}
