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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SharedDecksDownloadViewModel.kt and
 * SharedDecksDownloadViewModelTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Shared Decks download state', () {
    test('starts with source defaults and retry resets all other fields', () {
      const initial = SharedDecksDownloadUiState();
      expect(initial.fileName, isNull);
      expect(initial.percent, 0.0);
      expect(initial.phase, DownloadPhase.downloading);
      expect(initial.isWaitingForNetwork, isFalse);

      final failed = downloadFailed(
        downloadWaitingForNetwork(
          downloadProgress(initial, downloadedBytes: 25, totalBytes: 100),
          waiting: true,
        ),
      );
      expect(failed.fileName, isNull);
      expect(failed.percent, 0.0);
      expect(failed.phase, DownloadPhase.failed);
      expect(failed.isWaitingForNetwork, isTrue);

      final retried = downloadStarted('Japanese Core 2000.apkg');

      expect(retried.fileName, 'Japanese Core 2000.apkg');
      expect(retried.percent, 0.0);
      expect(retried.phase, DownloadPhase.downloading);
      expect(retried.isWaitingForNetwork, isFalse);
    });

    test(
      'progress uses Float32 source arithmetic, absolute value, and no clamp',
      () {
        final rounded = downloadProgress(
          const SharedDecksDownloadUiState(),
          downloadedBytes: 16_777_219,
          totalBytes: 16_777_216,
        );
        expect(rounded.percent, 100.0000228881836);

        final negative = downloadProgress(
          const SharedDecksDownloadUiState(),
          downloadedBytes: -25,
          totalBytes: 200,
        );
        expect(negative.percent, 12.5);

        final unknown = downloadProgress(
          const SharedDecksDownloadUiState(),
          downloadedBytes: 5_000,
          totalBytes: 0,
        );
        final negativeUnknown = downloadProgress(
          const SharedDecksDownloadUiState(),
          downloadedBytes: 5_000,
          totalBytes: -1,
        );
        expect(unknown.percent, 0.0);
        expect(negativeUnknown.percent, 0.0);
      },
    );

    test(
      'unavailable progress and network waiting update only their fields',
      () {
        const state = SharedDecksDownloadUiState(
          fileName: 'deck.apkg',
          percent: 42.5,
          phase: DownloadPhase.failed,
        );

        final unavailable = downloadProgressUnavailable(state);
        expect(unavailable.fileName, state.fileName);
        expect(unavailable.percent, isNull);
        expect(unavailable.phase, state.phase);
        expect(unavailable.isWaitingForNetwork, state.isWaitingForNetwork);

        final waiting = downloadWaitingForNetwork(unavailable, waiting: true);
        expect(waiting.fileName, state.fileName);
        expect(waiting.percent, isNull);
        expect(waiting.phase, state.phase);
        expect(waiting.isWaitingForNetwork, isTrue);
      },
    );

    test(
      'complete and failure set phase and percent while retaining other fields',
      () {
        const state = SharedDecksDownloadUiState(
          fileName: 'deck.apkg',
          percent: 42.5,
          isWaitingForNetwork: true,
        );

        final completed = downloadCompleted(state);
        expect(completed.fileName, state.fileName);
        expect(completed.percent, 100.0);
        expect(completed.phase, DownloadPhase.complete);
        expect(completed.isWaitingForNetwork, isTrue);

        final failed = downloadFailed(state);
        expect(failed.fileName, state.fileName);
        expect(failed.percent, 0.0);
        expect(failed.phase, DownloadPhase.failed);
        expect(failed.isWaitingForNetwork, isTrue);
      },
    );

    test(
      'integer percent branches match source and fractional display is host-formatted',
      () {
        final formatted = <String>[];
        String hostFormat(double value, int fractionDigits) {
          formatted.add('$value:$fractionDigits');
          return 'locale-value';
        }

        expect(formatDownloadPercent(0, localeFormatter: hostFormat), '0');
        expect(formatDownloadPercent(100, localeFormatter: hostFormat), '100');
        expect(formatDownloadPercent(0.5, localeFormatter: hostFormat), '0');
        expect(
          formatDownloadPercent(double.nan, localeFormatter: hostFormat),
          '0',
        );
        expect(
          formatDownloadPercent(100.5, localeFormatter: hostFormat),
          '100',
        );
        expect(
          formatDownloadPercent(42.75, localeFormatter: hostFormat),
          'locale-value',
        );
        expect(
          formatDownloadPercent(double.infinity, localeFormatter: hostFormat),
          'locale-value',
        );
        expect(formatted, ['42.75:1', 'Infinity:1']);
      },
    );
  });
}
