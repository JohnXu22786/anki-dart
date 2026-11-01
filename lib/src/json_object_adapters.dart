/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
 * Copyright (c) 2024 Ashish Yadav <mailtoashish693@gmail.com>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONObject.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts `JSONObject.getStringOrNull(key)` while retaining host JSON behavior.
String? jsonObjectGetStringOrNull({
  required String key,
  required bool Function(String key) has,
  required bool Function(String key) isNull,
  required String Function(String key) getString,
}) {
  if (!has(key)) return null;
  if (isNull(key)) return null;
  try {
    return getString(key);
  } on Exception {
    return null;
  }
}

/// Lazily projects `JSONObject.jsonObjectIterable()` as a re-iterable sequence.
///
/// The host supplies fresh object keys and typed object reads on each iteration.
Iterable<TObject> jsonObjectIterable<TObject>({
  required Iterable<String> Function() keys,
  required TObject Function(String key) getJSONObject,
}) sync* {
  for (final key in keys()) {
    yield getJSONObject(key);
  }
}
