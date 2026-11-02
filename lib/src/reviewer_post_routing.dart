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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Routes the portable part of `ReviewerViewModel.handlePostRequest()`.
///
/// The host supplies parsed method names, its exact request object, and received
/// bytes. It owns URI parsing, byte transport, focus state, state-mutation
/// signals, scheduling-state parsing and persistence, coroutine execution,
/// CardViewer handling, and HTTP/WebView lifecycle. Branches preserve source
/// order, and host callback failures propagate before any later route runs.
Future<List<int>> routeReviewerPostRequest<Request>({
  required String? ankidroidMethodName,
  required String? backendMethodName,
  required Request request,
  required List<int> bytes,
  required FutureOr<void> Function(bool isInputFocused) setInputFocusedRaw,
  required FutureOr<void> Function() statesMutatedRaw,
  required FutureOr<List<int>> Function() getSchedulingStatesWithContextRaw,
  required FutureOr<void> Function(List<int> bytes) setSchedulingStatesRaw,
  required FutureOr<List<int>> Function(Request request, List<int> bytes)
  baseHandler,
}) async {
  if (ankidroidMethodName == 'focusin') {
    await setInputFocusedRaw(true);
    return const <int>[];
  }

  if (ankidroidMethodName == 'focusout') {
    await setInputFocusedRaw(false);
    return const <int>[];
  }

  if (ankidroidMethodName == 'statesMutated') {
    await statesMutatedRaw();
    return const <int>[];
  }

  if (backendMethodName == 'getSchedulingStatesWithContext') {
    return await getSchedulingStatesWithContextRaw();
  }

  if (backendMethodName == 'setSchedulingStates') {
    await setSchedulingStatesRaw(bytes);
    return const <int>[];
  }

  return await baseHandler(request, bytes);
}
