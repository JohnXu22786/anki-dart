/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'browser_note_editor_destination.dart';

/// A source-mapped command for the Card Browser's post-search editor pane.
sealed class BrowserPostSearchPaneCommand {
  const BrowserPostSearchPaneCommand();
}

/// Show the pane with the already resolved editor destination.
final class BrowserPostSearchPaneLoadInPane
    extends BrowserPostSearchPaneCommand {
  const BrowserPostSearchPaneLoadInPane(this.destination);

  /// The exact destination supplied by the host.
  final BrowserEditSelectionDestination destination;
}

/// Hide the pane because no valid editor destination is available.
final class BrowserPostSearchPaneHidePane extends BrowserPostSearchPaneCommand {
  const BrowserPostSearchPaneHidePane();
}

/// Maps the host-resolved destination to AnkiDroid's post-search pane command.
///
/// The host passes null when the pane row is missing or destination resolution
/// returns no valid edit destination. This projection does not look up rows or
/// destinations and does not deliver the command.
BrowserPostSearchPaneCommand browserPostSearchPaneCommand({
  required BrowserEditSelectionDestination? destination,
}) => destination == null
    ? const BrowserPostSearchPaneHidePane()
    : BrowserPostSearchPaneLoadInPane(destination);
