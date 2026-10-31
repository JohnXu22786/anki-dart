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
 * Source-derived cases for TtsVoicesViewModel.availableVoicesFlow;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('available TTS voice projection', () {
    test('engine error takes precedence over voice-list error by identity', () {
      final engineError = FormatException('engine failed');
      final listError = FormatException('list failed');

      final state = projectAvailableVoices<_Voice>(
        engineStatus: TtsEngineError(engineError),
        voiceListStatus: LoadVoiceError(listError),
        filters: const TtsVoiceFilters(
          showInternetEnabled: false,
          showNotInstalled: false,
        ),
        unavailable: (voice) => voice.unavailable,
        isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
      );

      expect(state, isA<VoiceLoadingFailure<_Voice>>());
      expect(
        (state as VoiceLoadingFailure<_Voice>).exception,
        same(engineError),
      );
    });

    test('voice-list error is returned unless the engine also failed', () {
      final listError = FormatException('list failed');
      final filters = const TtsVoiceFilters(
        showInternetEnabled: false,
        showNotInstalled: false,
      );

      for (final engineStatus in <TtsEngineStatus>[
        const TtsEngineUninitialized(),
        const TtsEngineLoading(),
        const TtsEngineSuccess(),
      ]) {
        final state = projectAvailableVoices<_Voice>(
          engineStatus: engineStatus,
          voiceListStatus: LoadVoiceError(listError),
          filters: filters,
          unavailable: (voice) => voice.unavailable,
          isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
        );

        expect(state, isA<VoiceLoadingFailure<_Voice>>());
        expect(
          (state as VoiceLoadingFailure<_Voice>).exception,
          same(listError),
        );
      }
    });

    test('only simultaneous engine and list success produces success', () {
      const filters = TtsVoiceFilters(
        showInternetEnabled: true,
        showNotInstalled: false,
      );
      const voice = _Voice('voice', unavailable: false);
      final engineStatuses = <TtsEngineStatus>[
        const TtsEngineUninitialized(),
        const TtsEngineLoading(),
        const TtsEngineSuccess(),
      ];
      final listStatuses = <LoadVoiceStatus<_Voice>>[
        const LoadVoiceCalculating(),
        LoadVoiceSuccess([voice]),
      ];

      for (final engineStatus in engineStatuses) {
        for (final listStatus in listStatuses) {
          final state = projectAvailableVoices<_Voice>(
            engineStatus: engineStatus,
            voiceListStatus: listStatus,
            filters: filters,
            unavailable: (voice) => voice.unavailable,
            isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
          );

          if (engineStatus is TtsEngineSuccess &&
              listStatus is LoadVoiceSuccess<_Voice>) {
            expect(state, isA<VoiceLoadingSuccess<_Voice>>());
          } else {
            expect(state, isA<VoiceLoadingPending<_Voice>>());
          }
        }
      }
    });

    test(
      'installed and unavailable filters preserve source order and items',
      () {
        final firstUnavailable = _Voice('first unavailable', unavailable: true);
        final installed = _Voice('installed', unavailable: false);
        final secondUnavailable = _Voice(
          'second unavailable',
          unavailable: true,
        );
        final sourceVoices = [firstUnavailable, installed, secondUnavailable];

        for (final showNotInstalled in [false, true]) {
          final state =
              projectAvailableVoices<_Voice>(
                    engineStatus: const TtsEngineSuccess(),
                    voiceListStatus: LoadVoiceSuccess(sourceVoices),
                    filters: TtsVoiceFilters(
                      showInternetEnabled: true,
                      showNotInstalled: showNotInstalled,
                    ),
                    unavailable: (voice) => voice.unavailable,
                    isNetworkConnectionRequired: (voice) =>
                        voice.requiresNetwork,
                  )
                  as VoiceLoadingSuccess<_Voice>;

          expect(
            state.voices,
            orderedEquals(
              showNotInstalled
                  ? [firstUnavailable, secondUnavailable]
                  : [installed],
            ),
          );
          expect(
            state.voices.every(
              (voice) => sourceVoices.any((source) => identical(voice, source)),
            ),
            isTrue,
          );
        }
      },
    );

    test('showing unavailable voices ignores internet-enabled preference', () {
      final unavailableNetworkVoice = _Voice(
        'unavailable network voice',
        unavailable: true,
        requiresNetwork: true,
      );
      final voices = [unavailableNetworkVoice];

      for (final showInternetEnabled in [false, true]) {
        final state =
            projectAvailableVoices<_Voice>(
                  engineStatus: const TtsEngineSuccess(),
                  voiceListStatus: LoadVoiceSuccess(voices),
                  filters: TtsVoiceFilters(
                    showInternetEnabled: showInternetEnabled,
                    showNotInstalled: true,
                  ),
                  unavailable: (voice) => voice.unavailable,
                  isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
                )
                as VoiceLoadingSuccess<_Voice>;

        expect(state.voices, orderedEquals([unavailableNetworkVoice]));
      }
    });

    test(
      'installed network voices require internet preference to be shown',
      () {
        final offlineVoice = _Voice('offline', unavailable: false);
        final networkVoice = _Voice(
          'network',
          unavailable: false,
          requiresNetwork: true,
        );
        final voices = [offlineVoice, networkVoice];

        final withoutInternet =
            projectAvailableVoices<_Voice>(
                  engineStatus: const TtsEngineSuccess(),
                  voiceListStatus: LoadVoiceSuccess(voices),
                  filters: const TtsVoiceFilters(
                    showInternetEnabled: false,
                    showNotInstalled: false,
                  ),
                  unavailable: (voice) => voice.unavailable,
                  isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
                )
                as VoiceLoadingSuccess<_Voice>;
        final withInternet =
            projectAvailableVoices<_Voice>(
                  engineStatus: const TtsEngineSuccess(),
                  voiceListStatus: LoadVoiceSuccess(voices),
                  filters: const TtsVoiceFilters(
                    showInternetEnabled: true,
                    showNotInstalled: false,
                  ),
                  unavailable: (voice) => voice.unavailable,
                  isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
                )
                as VoiceLoadingSuccess<_Voice>;

        expect(withoutInternet.voices, orderedEquals([offlineVoice]));
        expect(
          withInternet.voices,
          orderedEquals([offlineVoice, networkVoice]),
        );
      },
    );

    test('empty source list remains successful empty result', () {
      final state = projectAvailableVoices<_Voice>(
        engineStatus: const TtsEngineSuccess(),
        voiceListStatus: LoadVoiceSuccess(const []),
        filters: const TtsVoiceFilters(
          showInternetEnabled: false,
          showNotInstalled: false,
        ),
        unavailable: (voice) => voice.unavailable,
        isNetworkConnectionRequired: (voice) => voice.requiresNetwork,
      );

      expect(state, isA<VoiceLoadingSuccess<_Voice>>());
      expect((state as VoiceLoadingSuccess<_Voice>).voices, isEmpty);
    });
  });
}

final class _Voice {
  const _Voice(
    this.name, {
    required this.unavailable,
    this.requiresNetwork = false,
  });

  final String name;
  final bool unavailable;
  final bool requiresNetwork;

  @override
  String toString() => name;
}
