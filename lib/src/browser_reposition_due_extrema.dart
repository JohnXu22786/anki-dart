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

import 'browser_reposition_queue_bounds.dart';

/// Maps host-read due extrema through AnkiDroid's reposition value rules.
///
/// The source clamps `minDue` at zero before constructing `RepositionData`,
/// while passing `maxDue` unchanged. The constructor then sorts the two values
/// into queue bounds. SQL and cursor access remain host-side.
BrowserRepositionQueueBounds projectBrowserRepositionDueExtrema({
  required int minDue,
  required int maxDue,
}) => projectBrowserRepositionQueueBounds(
  min: minDue < 0 ? 0 : minDue,
  max: maxDue,
);
