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
 * Source-derived from CardTemplateFragment.onCardBrowserAppearanceResult in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'card_template_browser_appearance_result.dart';

/// Applies a parsed browser-appearance result to the host's current template.
///
/// The host [parse] callback reads the Android Intent and retains the parser's
/// inner exception logging. The host [readCurrentTemplate] callback performs
/// the backend lookup and keeps its source exception boundary; it returns
/// whether a current template was found while keeping the model host-side. The
/// setters close over that host-owned template. Logging and template callbacks
/// run in source order, and failures propagate immediately.
void applyBrowserAppearanceResult({
  required BrowserAppearanceResult? Function() parse,
  required void Function(String) warn,
  required void Function(String) info,
  required bool Function() readCurrentTemplate,
  required void Function(String) setBqfmt,
  required void Function(String) setBafmt,
  required void Function() updateDiscardChangeState,
}) {
  final result = parse();
  if (result == null) {
    warn('Error processing Card Template Browser Appearance result');
    return;
  }

  info('Applying Card Template Browser Appearance result');
  if (!readCurrentTemplate()) return;

  result.applyTo(setBqfmt: setBqfmt, setBafmt: setBafmt);
  updateDiscardChangeState();
}
