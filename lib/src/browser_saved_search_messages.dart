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

import 'browser_saved_searches.dart';

/// Identifies which saved-search mutation produced a source user-message kind.
enum BrowserSavedSearchMutationOperation { add, delete }

/// The four user-message identifiers emitted by AnkiDroid's Card Browser.
///
/// These are message keys, not localized text. The host owns localization and
/// delivery through its UI message flow.
enum BrowserSavedSearchUserMessage {
  SEARCH_SAVED,
  SAVED_SEARCH_DUPLICATE_ADDED,
  SAVED_SEARCH_NAME_DOES_NOT_EXIST,
  SAVED_SEARCH_DELETED,
}

/// The mutation result shape returned by [BrowserSavedSearchesModel].
typedef BrowserSavedSearchMutationResult = (bool, List<BrowserSavedSearch>);

/// Maps the success flag in an existing saved-search mutation result to the
/// source message kind, without changing or consuming its resulting list.
BrowserSavedSearchUserMessage browserSavedSearchUserMessageForMutation({
  required BrowserSavedSearchMutationOperation operation,
  required BrowserSavedSearchMutationResult result,
}) =>
    switch ((operation, result.$1)) {
      (BrowserSavedSearchMutationOperation.add, true) =>
        BrowserSavedSearchUserMessage.SEARCH_SAVED,
      (BrowserSavedSearchMutationOperation.add, false) =>
        BrowserSavedSearchUserMessage.SAVED_SEARCH_DUPLICATE_ADDED,
      (BrowserSavedSearchMutationOperation.delete, true) =>
        BrowserSavedSearchUserMessage.SAVED_SEARCH_DELETED,
      (BrowserSavedSearchMutationOperation.delete, false) =>
        BrowserSavedSearchUserMessage.SAVED_SEARCH_NAME_DOES_NOT_EXIST,
    };
