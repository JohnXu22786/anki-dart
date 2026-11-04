/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

const _cardDescriptionSkippedFields = <String>{
  'Companion',
  'SKIP_PRINT',
  r'$assertionsDisabled',
  'note',
  'renderOutput',
  'timerStarted',
  'col',
};

/// Adapts `Card.toString()` (LibAnki alias `description`) using host reflection.
///
/// The host supplies [declaredFieldNames] in its declared-field order, reads
/// each non-skipped field, and stringifies its value. [isReflectionFailure]
/// identifies only the host's `IllegalAccessException` and
/// `IllegalArgumentException` categories; those produce `N/A`, while all other
/// failures propagate unchanged.
String libankiCardDescription({
  required Iterable<String> declaredFieldNames,
  required Object? Function(String fieldName) readField,
  required String Function(Object? value) stringifyValue,
  required bool Function(Object error) isReflectionFailure,
}) {
  final members = <String>[];
  for (final fieldName in declaredFieldNames) {
    if (_cardDescriptionSkippedFields.contains(fieldName)) continue;
    try {
      final value = stringifyValue(readField(fieldName));
      members.add("'$fieldName': $value");
    } catch (error) {
      if (!isReflectionFailure(error)) rethrow;
      members.add("'$fieldName': N/A");
    }
  }
  return members.join(',  ');
}
