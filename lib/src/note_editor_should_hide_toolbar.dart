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
 * Source-derived from NoteEditorFragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Preference key read by `NoteEditorFragment.shouldHideToolbar()`.
const noteEditorShowToolbarPreferenceKey = 'noteEditorShowToolbar';

/// Reads and negates the note editor's toolbar visibility preference.
///
/// [sharedPrefs] represents `appContext.sharedPrefs()` and runs once before
/// [getBoolean]. The Boolean is read once with the source key and a `true`
/// default, then negated as in the Kotlin source. App context and preference
/// storage remain host-side; callback failures propagate unchanged.
bool noteEditorShouldHideToolbar<TPreferences>({
  required TPreferences Function() sharedPrefs,
  required bool Function(
    TPreferences preferences,
    String key,
    bool defaultValue,
  )
  getBoolean,
}) {
  final preferences = sharedPrefs();
  return !getBoolean(preferences, noteEditorShowToolbarPreferenceKey, true);
}
