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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserSearchViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_search_request.dart';
import 'kotlin_whitespace.dart';

/// Whether a Card Browser filter state came from the user or system syncing.
///
/// The source starts at [initial]. The host supplies snapshots after its state
/// flow updates; this type does not schedule or combine those updates.
sealed class BrowserFilterUpdate {
  const BrowserFilterUpdate(this.state);

  final BrowserSearchFilters state;

  /// The source's initial `System(SearchFilters.EMPTY)` state.
  static const BrowserFilterUpdate initial =
      BrowserFilterUpdateSystem(BrowserSearchFilters());
}

/// A user-originated filter change that can initiate a search when closed.
final class BrowserFilterUpdateUser extends BrowserFilterUpdate {
  const BrowserFilterUpdateUser(super.state);

  @override
  bool operator ==(Object other) =>
      other is BrowserFilterUpdateUser && other.state == state;

  // The source data class hashes only its constructor property, `state`.
  @override
  int get hashCode => state.hashCode;
}

/// A system-originated update, such as synchronization or reset.
final class BrowserFilterUpdateSystem extends BrowserFilterUpdate {
  const BrowserFilterUpdateSystem(super.state);

  @override
  bool operator ==(Object other) =>
      other is BrowserFilterUpdateSystem && other.state == state;

  // The source data class hashes only its constructor property, `state`.
  @override
  int get hashCode => state.hashCode;
}

/// Projects one source filter/text/screen snapshot into a search request.
///
/// Returns null while the search screen is open or for system-originated
/// updates. A closed-screen user update trims [text] with Kotlin
/// `String.trim()` semantics and carries its filters unchanged. The host owns
/// flow combination, cancellation, collection access, and search execution.
BrowserSearchRequest? browserSearchRequestFromFilterUpdate({
  required String text,
  required BrowserFilterUpdate update,
  required bool isScreenOpen,
}) {
  if (isScreenOpen || update is BrowserFilterUpdateSystem) return null;

  return BrowserSearchRequest(
    query: trimKotlinWhitespace(text),
    filters: update.state,
  );
}
