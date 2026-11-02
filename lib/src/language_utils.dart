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
 * Source-derived from LanguageUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Java `Character.DIRECTIONALITY_RIGHT_TO_LEFT`.
const int javaCharacterDirectionalityRightToLeft = 1;

/// Java `Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC`.
const int javaCharacterDirectionalityRightToLeftArabic = 2;

/// Java `Character.DIRECTIONALITY_LEFT_TO_RIGHT`.
const int javaCharacterDirectionalityLeftToRight = 0;

/// Java `Character.DIRECTIONALITY_OTHER_NEUTRALS`.
const int javaCharacterDirectionalityOtherNeutral = 13;

/// Constructs a host Locale from the language tag selected from a Locale string.
typedef LocaleForLanguageTag<T> = T Function(String languageTag);

/// Returns Java Character directionality for one UTF-16 code unit.
typedef CharacterGetDirectionality = int Function(int codeUnit);

/// Maps a `Locale.toString()`-style value to the host's Locale construction.
///
/// The suffix beginning with the first `#` is discarded. One, two, and three
/// underscore-separated fields become language tags joined with `-`; any other
/// field count is passed to the host constructor as an empty tag. The host owns
/// `Locale.forLanguageTag` behavior.
T localeFromStringIgnoringScriptAndExtensions<T>(
  String localeCodeStr, {
  required LocaleForLanguageTag<T> localeForLanguageTag,
}) {
  final hashIndex = localeCodeStr.indexOf('#');
  final localeCode = hashIndex < 0
      ? localeCodeStr
      : localeCodeStr.substring(0, hashIndex);
  final fields = localeCode.split('_');

  final languageTag = switch (fields.length) {
    1 => fields[0],
    2 => '${fields[0]}-${fields[1]}',
    3 => '${fields[0]}-${fields[1]}-${fields[2]}',
    _ => '',
  };

  return localeForLanguageTag(languageTag);
}

/// Projects whether the host-resolved locale display name begins RTL.
///
/// The host supplies Java `Character.getDirectionality` semantics. Only its
/// `RIGHT_TO_LEFT` and `RIGHT_TO_LEFT_ARABIC` results are considered RTL.
bool appLanguageIsRTL(
  String localeDisplayName, {
  required CharacterGetDirectionality characterGetDirectionality,
}) {
  if (localeDisplayName.isEmpty) return false;

  final firstCodeUnit = localeDisplayName.codeUnits.first;
  final directionality = characterGetDirectionality(firstCodeUnit);
  return directionality == javaCharacterDirectionalityRightToLeft ||
      directionality == javaCharacterDirectionalityRightToLeftArabic;
}
