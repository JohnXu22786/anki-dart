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
 * Locale-sensitive case mapping used by the deck-filter port. Unicode data is
 * kept in unicode_15_case_data.dart under its separate license.
 */

import 'dart:io' show Platform;

import 'unicode_15_case_data.dart';

String localeLowercase(String value, String localeName) {
  final effectiveLocaleName =
      localeName.isEmpty ? Platform.localeName : localeName;
  final language =
      effectiveLocaleName.replaceAll('_', '-').split('-').first.toLowerCase();
  if (language == 'tr' || language == 'az') {
    return _lowercaseTurkic(value);
  }
  if (language == 'lt') {
    return _lowercaseLithuanian(value);
  }
  return unicodeLowercase(value);
}

/// Applies Unicode's locale-invariant full lowercase mapping.
String unicodeLowercase(String value) => _lowercaseDefaultWithFinalSigma(value);

String _lowercaseTurkic(String value) {
  final runes = value.runes.toList(growable: false);
  final result = StringBuffer();

  for (var index = 0; index < runes.length; index++) {
    final rune = runes[index];
    if (rune == 0x0130) {
      result.write('i');
    } else if (rune == 0x0049) {
      result.write(_hasTurkicDotAhead(runes, index + 1) ? 'I' : 'ı');
    } else if (rune == 0x0307 && _hasTurkicCapitalIBefore(runes, index)) {
      continue;
    } else {
      result.writeCharCode(rune);
    }
  }

  return _lowercaseDefaultWithFinalSigma(result.toString());
}

String _lowercaseLithuanian(String value) {
  final runes = value.runes.toList(growable: false);
  final result = StringBuffer();

  for (var index = 0; index < runes.length; index++) {
    final rune = runes[index];
    if (rune == 0x00CC) {
      result.write('i\u0307\u0300');
    } else if (rune == 0x00CD) {
      result.write('i\u0307\u0301');
    } else if (rune == 0x0128) {
      result.write('i\u0307\u0303');
    } else if (rune == 0x0307 && _hasSoftDottedBefore(runes, index)) {
      continue;
    } else if ((rune == 0x0049 || rune == 0x004A || rune == 0x012E) &&
        _hasMoreAbove(runes, index + 1)) {
      result.writeCharCode(rune);
      result.write('\u0307');
    } else {
      result.writeCharCode(rune);
    }
  }

  return _lowercaseDefaultWithFinalSigma(result.toString());
}

String _lowercaseDefaultWithFinalSigma(String value) {
  final runes = value.runes.toList(growable: false);
  final result = StringBuffer();

  for (var index = 0; index < runes.length; index++) {
    final rune = runes[index];
    if (rune == 0x03A3 && _isFinalSigma(runes, index)) {
      result.writeCharCode(0x03C2);
    } else {
      result.write(
        unicode15FullLowercaseMappings[rune] ??
            String.fromCharCode(rune).toLowerCase(),
      );
    }
  }

  return result.toString();
}

bool _isFinalSigma(List<int> runes, int index) {
  var hasCasedBefore = false;
  for (var cursor = index - 1; cursor >= 0; cursor--) {
    final rune = runes[cursor];
    if (_isUnicodeCaseIgnorable(rune)) continue;
    if (_isUnicodeCased(rune)) {
      hasCasedBefore = true;
      break;
    }
    return false;
  }
  if (!hasCasedBefore) return false;

  for (var cursor = index + 1; cursor < runes.length; cursor++) {
    final rune = runes[cursor];
    if (_isUnicodeCaseIgnorable(rune)) continue;
    if (_isUnicodeCased(rune)) return false;
    return true;
  }
  return true;
}

bool _isUnicodeCased(int rune) =>
    _isInCodePointRanges(unicode15CasedRanges, rune);

bool _isUnicodeCaseIgnorable(int rune) =>
    _isInCodePointRanges(unicode15CaseIgnorableRanges, rune);

bool _hasTurkicDotAhead(List<int> runes, int start) {
  for (var index = start; index < runes.length; index++) {
    final rune = runes[index];
    if (rune == 0x0307) return true;
    if (!_isCombiningClassNonzero(rune) || _isCombiningClass230(rune)) {
      return false;
    }
  }
  return false;
}

bool _hasTurkicCapitalIBefore(List<int> runes, int start) =>
    _hasContextBaseBefore(runes, start, 0x0049);

bool _hasSoftDottedBefore(List<int> runes, int start) {
  for (var index = start - 1; index >= 0; index--) {
    final rune = runes[index];
    if (!_isCombiningClassNonzero(rune) || _isCombiningClass230(rune)) {
      return _isInCodePointRanges(unicode15SoftDottedRanges, rune);
    }
  }
  return false;
}

bool _hasContextBaseBefore(List<int> runes, int start, int base) {
  for (var index = start - 1; index >= 0; index--) {
    final rune = runes[index];
    if (!_isCombiningClassNonzero(rune) || _isCombiningClass230(rune)) {
      return rune == base;
    }
  }
  return false;
}

bool _hasMoreAbove(List<int> runes, int start) {
  for (var index = start; index < runes.length; index++) {
    final rune = runes[index];
    if (!_isCombiningClassNonzero(rune)) {
      return false;
    }
    if (_isCombiningClass230(rune)) {
      return true;
    }
  }
  return false;
}

bool _isCombiningClassNonzero(int rune) =>
    _isInCodePointRanges(unicode15CombiningClassNonzeroRanges, rune);

bool _isCombiningClass230(int rune) =>
    _isInCodePointRanges(unicode15CombiningClass230Ranges, rune);

bool _isInCodePointRanges(List<int> ranges, int rune) {
  var low = 0;
  var high = ranges.length ~/ 2 - 1;
  while (low <= high) {
    final middle = (low + high) ~/ 2;
    final start = ranges[middle * 2];
    final end = ranges[middle * 2 + 1];
    if (rune < start) {
      high = middle - 1;
    } else if (rune > end) {
      low = middle + 1;
    } else {
      return true;
    }
  }
  return false;
}
