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
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from BackendStats.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Host operations needed to preserve `BackendStats` raw wrapper behavior.
///
/// The host owns generated protobuf values and backend transport. This adapter
/// supplies only the raw calls and graph-preference builder operations used by
/// the source wrapper.
final class BackendStatsRawCallbacks<TPreferences, TBuilder> {
  const BackendStatsRawCallbacks({
    required this.cardStatsRaw,
    required this.graphsRaw,
    required this.setGraphPreferencesRaw,
    required this.getGraphPreferences,
    required this.toBuilder,
    required this.setBrowserLinksSupported,
    required this.buildGraphPreferences,
    required this.serializeGraphPreferences,
  });

  final Uint8List Function(Uint8List input) cardStatsRaw;
  final Uint8List Function(Uint8List input) graphsRaw;
  final Uint8List Function(Uint8List input) setGraphPreferencesRaw;
  final TPreferences Function() getGraphPreferences;
  final TBuilder Function(TPreferences preferences) toBuilder;
  final void Function(TBuilder builder, bool enabled) setBrowserLinksSupported;
  final TPreferences Function(TBuilder builder) buildGraphPreferences;
  final Uint8List Function(TPreferences preferences) serializeGraphPreferences;
}

/// Portable raw-statistics wrapper around host-provided backend operations.
///
/// Raw byte calls pass their input and result through unchanged. Graph
/// preferences are copied through the host builder, with browser links disabled
/// before the built value is serialized. Host callback exceptions propagate.
final class BackendStatsRaw<TPreferences, TBuilder> {
  const BackendStatsRaw(this.callbacks);

  final BackendStatsRawCallbacks<TPreferences, TBuilder> callbacks;

  Uint8List cardStatsRaw(Uint8List input) => callbacks.cardStatsRaw(input);

  Uint8List graphsRaw(Uint8List input) => callbacks.graphsRaw(input);

  Uint8List setGraphPreferencesRaw(Uint8List input) =>
      callbacks.setGraphPreferencesRaw(input);

  Uint8List getGraphPreferencesRaw() {
    final builder = callbacks.toBuilder(callbacks.getGraphPreferences());
    callbacks.setBrowserLinksSupported(builder, false);
    final preferences = callbacks.buildGraphPreferences(builder);
    return callbacks.serializeGraphPreferences(preferences);
  }
}
