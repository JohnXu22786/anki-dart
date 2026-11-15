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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

final _flagSearchTermRegex = RegExp(
  r'flag:[^\r\n\u0085\u2028\u2029]',
  unicode: true,
);

/// Applies the query-text part of `CardBrowserViewModel.setFlagFilter()`.
///
/// [flagCode] is the source `Flag.code` value supplied by the host. This keeps
/// AnkiDroid's legacy query-string replacement separate from flag UI and search
/// execution.
String browserSearchTermsWithFlag({
  required String searchTerms,
  required int flagCode,
}) {
  final flagSearchTerm = 'flag:$flagCode';
  if (searchTerms.contains('flag:')) {
    return searchTerms.replaceFirst(_flagSearchTermRegex, flagSearchTerm);
  }
  if (searchTerms.isNotEmpty) return '$flagSearchTerm $searchTerms';
  return flagSearchTerm;
}
