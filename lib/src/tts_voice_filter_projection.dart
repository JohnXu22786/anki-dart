/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version. This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
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

/// State of the host's TTS engine while voice previews are being prepared.
sealed class TtsEngineStatus {
  const TtsEngineStatus();
}

/// The host has not started initializing the TTS engine.
final class TtsEngineUninitialized extends TtsEngineStatus {
  const TtsEngineUninitialized();
}

/// The host is initializing the TTS engine.
final class TtsEngineLoading extends TtsEngineStatus {
  const TtsEngineLoading();
}

/// The host has a ready TTS engine.
final class TtsEngineSuccess extends TtsEngineStatus {
  const TtsEngineSuccess();
}

/// The host encountered an error while initializing the TTS engine.
final class TtsEngineError extends TtsEngineStatus {
  const TtsEngineError(this.exception);

  final Exception exception;
}

/// State of the host's TTS voice enumeration.
sealed class LoadVoiceStatus<T> {
  const LoadVoiceStatus();
}

/// The host is still calculating or refreshing available voices.
final class LoadVoiceCalculating<T> extends LoadVoiceStatus<T> {
  const LoadVoiceCalculating();
}

/// The host has supplied its enumerated and sorted voices.
final class LoadVoiceSuccess<T> extends LoadVoiceStatus<T> {
  const LoadVoiceSuccess(this.voices);

  final List<T> voices;
}

/// The host encountered an error while enumerating voices.
final class LoadVoiceError<T> extends LoadVoiceStatus<T> {
  const LoadVoiceError(this.exception);

  final Exception exception;
}

/// Filters applied to the successful voice list.
final class TtsVoiceFilters {
  const TtsVoiceFilters({
    required this.showInternetEnabled,
    required this.showNotInstalled,
  });

  final bool showInternetEnabled;
  final bool showNotInstalled;
}

/// State published by the host-facing available-voices projection.
sealed class VoiceLoadingState<T> {
  const VoiceLoadingState();
}

/// Available voices after applying [TtsVoiceFilters].
final class VoiceLoadingSuccess<T> extends VoiceLoadingState<T> {
  const VoiceLoadingSuccess(this.voices);

  final List<T> voices;
}

/// The engine or voice list has not completed loading.
final class VoiceLoadingPending<T> extends VoiceLoadingState<T> {
  const VoiceLoadingPending();
}

/// Loading failed with the exact host exception object.
final class VoiceLoadingFailure<T> extends VoiceLoadingState<T> {
  const VoiceLoadingFailure(this.exception);

  final Exception exception;
}

/// Projects the source's engine/list statuses and filters to the UI state.
///
/// [voices] are supplied in host order (the Android host sorts by locale and
/// localized name). The host also supplies source-equivalent availability and
/// network facts for each item. This function preserves that order and each
/// item object; it does not enumerate, sort, normalize, or deduplicate voices.
VoiceLoadingState<T> projectAvailableVoices<T>({
  required TtsEngineStatus engineStatus,
  required LoadVoiceStatus<T> voiceListStatus,
  required TtsVoiceFilters filters,
  required bool Function(T voice) unavailable,
  required bool Function(T voice) isNetworkConnectionRequired,
}) {
  if (engineStatus case TtsEngineError(:final exception)) {
    return VoiceLoadingFailure<T>(exception);
  }
  if (voiceListStatus case LoadVoiceError<T>(:final exception)) {
    return VoiceLoadingFailure<T>(exception);
  }

  if (engineStatus is! TtsEngineSuccess ||
      voiceListStatus is! LoadVoiceSuccess<T>) {
    return VoiceLoadingPending<T>();
  }

  // This mirrors `showNotInstalled == voice.unavailable()` in the source.
  final matchingVoices = voiceListStatus.voices
      .where((voice) => filters.showNotInstalled == unavailable(voice))
      .toList();
  if (filters.showNotInstalled) {
    return VoiceLoadingSuccess<T>(matchingVoices);
  }

  return VoiceLoadingSuccess<T>(
    matchingVoices
        .where(
          (voice) =>
              filters.showInternetEnabled ||
              !isNetworkConnectionRequired(voice),
        )
        .toList(),
  );
}
