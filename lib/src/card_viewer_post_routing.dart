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
 * Behavioral reference: CardViewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Routes the portable part of `CardViewerViewModel.handlePostRequest()`.
///
/// The host supplies the already parsed backend method, URI rendering, and
/// received bytes. It also owns URI parsing, transport, resource lookup, and
/// HTTP handling. Only the exact `i18nResources` method is delegated; errors
/// retain the source branch and use the host-supplied URI rendering verbatim.
Future<void> routeCardViewerPostRequest({
  required String? backendMethodName,
  required String uri,
  required List<int> bytes,
  required FutureOr<void> Function(List<int> bytes) i18nResourcesRaw,
}) async {
  if (backendMethodName == null) {
    throw ArgumentError('Unhandled POST request: $uri');
  }

  if (backendMethodName == 'i18nResources') {
    await i18nResourcesRaw(bytes);
    return;
  }

  throw ArgumentError('Unhandled Anki request: $uri');
}
