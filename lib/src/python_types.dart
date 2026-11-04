/*
 * Copyright © 2021 David Allison for the upstream aliases.
 * Copyright © 2026 John Tsui for the Dart adaptation.
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
 * SPDX-FileCopyrightText: 2021 David Allison (upstream aliases)
 * SPDX-FileCopyrightText: 2026 John Tsui (Dart adaptation)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from PythonTypes.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Identifier of a deck, represented by its creation time in milliseconds
/// since the Unix epoch (except for the default deck ID).
///
/// This is an alias of [EpochMilliseconds], matching Kotlin's source alias.
typedef DeckId = EpochMilliseconds;

/// Identifier of a card.
typedef CardId = int;

/// Identifier of a deck configuration.
typedef DeckConfigId = int;

/// Identifier of a note.
typedef NoteId = int;

/// Identifier of a note type.
typedef NoteTypeId = int;

/// Non-leap seconds elapsed since the Unix epoch.
typedef EpochSeconds = int;

/// Non-leap milliseconds elapsed since the Unix epoch.
typedef EpochMilliseconds = int;
