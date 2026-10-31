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
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SharedDecksDownloadViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// How far a Shared Decks download has got.
enum DownloadPhase { downloading, complete, failed }

/// Values shown by AnkiDroid's Shared Decks download screen.
final class SharedDecksDownloadUiState {
  const SharedDecksDownloadUiState({
    this.fileName,
    this.percent = 0.0,
    this.phase = DownloadPhase.downloading,
    this.isWaitingForNetwork = false,
  });

  final String? fileName;
  final double? percent;
  final DownloadPhase phase;
  final bool isWaitingForNetwork;

  SharedDecksDownloadUiState _withPercent(double? value) =>
      SharedDecksDownloadUiState(
        fileName: fileName,
        percent: value,
        phase: phase,
        isWaitingForNetwork: isWaitingForNetwork,
      );

  SharedDecksDownloadUiState _withWaitingForNetwork(bool value) =>
      SharedDecksDownloadUiState(
        fileName: fileName,
        percent: percent,
        phase: phase,
        isWaitingForNetwork: value,
      );

  SharedDecksDownloadUiState _withPhaseAndPercent(
    DownloadPhase value,
    double newPercent,
  ) => SharedDecksDownloadUiState(
    fileName: fileName,
    percent: newPercent,
    phase: value,
    isWaitingForNetwork: isWaitingForNetwork,
  );

  @override
  bool operator ==(Object other) =>
      other is SharedDecksDownloadUiState &&
      other.fileName == fileName &&
      other.percent == percent &&
      other.phase == phase &&
      other.isWaitingForNetwork == isWaitingForNetwork;

  @override
  int get hashCode =>
      Object.hash(fileName, percent, phase, isWaitingForNetwork);
}

/// Replaces all state with the source defaults and the exact supplied name.
/// The source calls this both when starting a new download and when retrying.
SharedDecksDownloadUiState downloadStarted(String fileName) =>
    SharedDecksDownloadUiState(fileName: fileName);

/// Updates only progress, retaining the source's Float32 arithmetic and abs.
SharedDecksDownloadUiState downloadProgress(
  SharedDecksDownloadUiState state, {
  required int downloadedBytes,
  required int totalBytes,
}) {
  final percent = totalBytes > 0
      ? _sourceFloat32(
          _sourceFloat32(_sourceFloat32(downloadedBytes.toDouble()) * 100.0) /
              _sourceFloat32(totalBytes.toDouble()),
        ).abs()
      : 0.0;
  return state._withPercent(percent);
}

/// Sets the percentage to null when the host cannot read download progress.
SharedDecksDownloadUiState downloadProgressUnavailable(
  SharedDecksDownloadUiState state,
) => state._withPercent(null);

/// Updates only the network-wait field.
SharedDecksDownloadUiState downloadWaitingForNetwork(
  SharedDecksDownloadUiState state, {
  required bool waiting,
}) => state._withWaitingForNetwork(waiting);

/// Marks the download complete and sets progress to 100.
SharedDecksDownloadUiState downloadCompleted(
  SharedDecksDownloadUiState state,
) => state._withPhaseAndPercent(DownloadPhase.complete, 100.0);

/// Marks the download failed and sets progress to zero.
SharedDecksDownloadUiState downloadFailed(SharedDecksDownloadUiState state) =>
    state._withPhaseAndPercent(DownloadPhase.failed, 0.0);

/// Formats a percentage using the source's integer branch and host locale.
///
/// The source uses `Float.toInt()` and returns that integer whenever it is 0 or
/// 100; other values use Java `"%.1f".format`, which reads the process default
/// locale. Dart has no process-default locale API, so the host supplies that
/// locale-aware, one-decimal formatter. This helper does not choose a decimal
/// symbol or implement locale-specific rounding.
String formatDownloadPercent(
  double percent, {
  required String Function(double percent, int fractionDigits) localeFormatter,
}) {
  final sourcePercent = _sourceFloat32(percent);
  final whole = _sourceFloatToInt(sourcePercent);
  return whole == 0 || whole == 100
      ? whole.toString()
      : localeFormatter(sourcePercent, 1);
}

double _sourceFloat32(double value) => (Float32List(1)..[0] = value)[0];

int _sourceFloatToInt(double value) {
  if (value.isNaN) return 0;
  if (value >= 2147483648.0) return 2147483647;
  if (value <= -2147483648.0) return -2147483648;
  return value.toInt();
}
