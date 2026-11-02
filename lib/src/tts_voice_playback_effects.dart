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
 * Behavioral reference: TtsVoicesViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'tts_voice_filter_projection.dart';

/// One host action selected by `TtsVoicesViewModel.playVoice()`.
sealed class TtsVoicePlaybackEffect<T> {
  const TtsVoicePlaybackEffect();
}

/// Emits the source's unavailable-voice notification for [voice].
final class NotifyUnavailableTtsVoiceEffect<T>
    extends TtsVoicePlaybackEffect<T> {
  const NotifyUnavailableTtsVoiceEffect(this.voice);

  final T voice;
}

/// Requests playback of [textToSpeak] with [voice].
final class PlayTtsVoiceEffect<T> extends TtsVoicePlaybackEffect<T> {
  const PlayTtsVoiceEffect({required this.textToSpeak, required this.voice});

  final String textToSpeak;
  final T voice;
}

/// Emits the exact non-null error returned by the host's TTS player.
final class EmitTtsPlaybackErrorEffect<E> extends TtsVoicePlaybackEffect<E> {
  const EmitTtsPlaybackErrorEffect(this.error);

  final E error;
}

/// Projects `playVoice()` and its `playTts()` readiness check into host effects.
///
/// The unavailable notification is selected before checking engine readiness,
/// as in the source. The host processes effects in order; it owns notification
/// delivery, player execution, and propagation of failures from those actions.
List<TtsVoicePlaybackEffect<T>> planTtsVoicePlayback<T>({
  required TtsEngineStatus engineStatus,
  required T voice,
  required String textToSpeak,
  required bool isUnavailable,
}) {
  final effects = <TtsVoicePlaybackEffect<T>>[];
  if (isUnavailable) {
    effects.add(NotifyUnavailableTtsVoiceEffect<T>(voice));
  }
  if (engineStatus is TtsEngineSuccess) {
    effects.add(PlayTtsVoiceEffect<T>(textToSpeak: textToSpeak, voice: voice));
  }
  return List.unmodifiable(effects);
}

/// Projects the source's nullable player result into its optional error event.
///
/// The host emits a returned error on its main-thread event path.
EmitTtsPlaybackErrorEffect<E>? projectTtsPlaybackError<E>(E? error) =>
    error == null ? null : EmitTtsPlaybackErrorEffect<E>(error);
