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
 * Source-derived from DeckPickerViewModel.kt:325 and ManageNotetypes.kt:348–350
 * in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The host-facing destination request for the Manage Note Types screen.
///
/// This intentionally has no const constructor or value equality: the source
/// creates a fresh `ManageNoteTypesDestination` for each action.
final class DeckPickerManageNoteTypesRequest {}

/// Projects `openManageNoteTypes` to a new host-facing destination request.
///
/// The host owns coroutine and flow delivery, Intent construction, and
/// navigation.
DeckPickerManageNoteTypesRequest projectDeckPickerOpenManageNoteTypes() =>
    DeckPickerManageNoteTypesRequest();
