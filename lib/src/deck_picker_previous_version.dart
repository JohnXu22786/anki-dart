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
 * Source-derived from AnkiDroid 2.25.3 DeckPickerViewModel.kt:659–692.
 */

/// Signals that a preference getter found a stored value of another JVM type.
///
/// The host adapter should translate only Android's `ClassCastException` from
/// the corresponding SharedPreferences getter into this exception. Other
/// failures must pass through unchanged.
final class DeckPickerPreferenceTypeMismatch implements Exception {
  const DeckPickerPreferenceTypeMismatch();
}

/// A value read through the JVM `Long` preference getter.
final class DeckPickerVersionLong {
  const DeckPickerVersionLong(this.value);

  final int value;
}

/// A value read through the JVM `Int` preference getter.
final class DeckPickerVersionInt {
  const DeckPickerVersionInt(this.value);

  final int value;
}

/// Host callbacks for the three source-typed SharedPreferences getters.
///
/// Keeping separate `getLong`, `getInt`, and `getString` callbacks allows a
/// host to preserve Android's runtime type checks and the JVM Long-versus-Int
/// distinction even though Dart's underlying numeric representation is `int`.
/// The host performs the actual IO.
class DeckPickerVersionPreferenceCallbacks {
  const DeckPickerVersionPreferenceCallbacks({
    required this.getLong,
    required this.getInt,
    required this.getString,
    required this.remove,
  });

  final DeckPickerVersionLong Function(
    String key,
    DeckPickerVersionLong defaultValue,
  )
  getLong;
  final DeckPickerVersionInt Function(
    String key,
    DeckPickerVersionInt defaultValue,
  )
  getInt;
  final String Function(String key, String defaultValue) getString;
  final void Function(String key) remove;
}

/// Returns the previous application version using the source getter order.
///
/// A successful Long read leaves the preference untouched. If the Long getter
/// reports a type mismatch, this tries Int with AnkiDroid's historical default
/// and then String with the exact legacy mapping. Successful fallback reads
/// remove the key; failures from the String read propagate without removal.
/// Persisting the current version remains the host's responsibility.
DeckPickerVersionLong getPreviousDeckPickerVersion({
  required DeckPickerVersionLong current,
  required DeckPickerVersionPreferenceCallbacks preferences,
}) {
  const key = 'lastUpgradeVersion';
  const intDefault = DeckPickerVersionInt(20900203);
  try {
    return preferences.getLong(key, current);
  } on DeckPickerPreferenceTypeMismatch {
    late final DeckPickerVersionLong previousVersion;
    try {
      previousVersion = DeckPickerVersionLong(
        preferences.getInt(key, intDefault).value,
      );
    } on DeckPickerPreferenceTypeMismatch {
      final storedVersion = preferences.getString(key, '');
      previousVersion = DeckPickerVersionLong(
        storedVersion == '2.0.2' ? 40 : 0,
      );
    }
    preferences.remove(key);
    return previousVersion;
  }
}
