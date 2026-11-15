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
 * SPDX-FileCopyrightText: 2026 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ExportReadyViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Immutable parameters for AnkiDroid's export-ready dialog request.
final class ExportReadyParams {
  const ExportReadyParams({required this.exportPath, this.asText = false});

  /// The original path string, preserved without normalization or access.
  final String exportPath;

  final bool asText;

  @override
  bool operator ==(Object other) =>
      other is ExportReadyParams &&
      other.exportPath == exportPath &&
      other.asText == asText;

  @override
  int get hashCode => Object.hash(exportPath, asText);
}

/// Portable request state from AnkiDroid's `ExportReadyViewModel`.
///
/// The host owns SavedStateHandle/StateFlow storage, Android lifecycle, Timber
/// logging, dialog/navigation, and filesystem/export execution.
final class ExportReadyRequestState {
  ExportReadyParams? _exportReadyDestination;

  ExportReadyParams? get exportReadyDestination => _exportReadyDestination;

  /// Stores [params] unchanged, matching `registerExportReadyRequest`.
  void registerExportReadyRequest(ExportReadyParams params) {
    _exportReadyDestination = params;
  }

  /// Clears the pending request, matching `clearExportReadyRequest`.
  void clearExportReadyRequest() {
    _exportReadyDestination = null;
  }
}
