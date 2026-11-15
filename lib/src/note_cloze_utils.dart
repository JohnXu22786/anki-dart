/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from Note.ClozeUtils.getNextClozeIndex in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

final _clozeRegex = RegExp(r'\{\{c(\d+)::');

/// Returns one greater than the highest cloze number found in [fieldValues].
///
/// This preserves the pinned source's signed 32-bit parsing and increment
/// behavior. Captured values outside Kotlin's `Int` range throw
/// [FormatException].
int getNextClozeIndex(Iterable<String> fieldValues) {
  var highestClozeId = 0;
  for (final fieldValue in fieldValues) {
    for (final match in _clozeRegex.allMatches(fieldValue)) {
      final detectedClozeId = int.parse(match.group(1)!);
      if (detectedClozeId > 0x7fffffff) {
        throw FormatException('Invalid signed 32-bit integer', match.group(1));
      }
      if (detectedClozeId > highestClozeId) {
        highestClozeId = detectedClozeId;
      }
    }
  }
  return highestClozeId == 0x7fffffff ? -0x80000000 : highestClozeId + 1;
}
