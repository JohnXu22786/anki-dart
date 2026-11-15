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
 * Source-derived from Shortcut.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_string_hash_code.dart';
import 'unicode_15_case_data.dart' show unicode15BmpDecimalDigitBlockStarts;

/// A keyboard shortcut and its already-localized display label.
///
/// Label construction and localization remain host-side.
final class Shortcut {
  const Shortcut({required this.shortcut, required this.label});

  final String shortcut;
  final String label;

  /// Projects this shortcut to host Android key-code and modifier values.
  ///
  /// The host supplies Android constants and `KeyEvent.keyCodeFromString` so
  /// this package does not depend on the Android SDK. Construction of
  /// `KeyboardShortcutInfo` remains host-side.
  ShortcutInfoProjection toShortcutInfo(ShortcutPlatformValues values) {
    final parts = shortcut.split('+');
    final key = parts.last;
    final keyCode = _getKey(key, values);
    final modifierFlags = parts
        .take(parts.length - 1)
        .fold<int>(
          0,
          (sum, modifier) => _int32(sum + _getModifier(modifier, values)),
        );

    return ShortcutInfoProjection(
      label: label,
      keyCode: keyCode,
      modifierFlags: modifierFlags,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Shortcut && other.shortcut == shortcut && other.label == label;

  @override
  int get hashCode =>
      _int32(31 * kotlinStringHashCode(shortcut) + kotlinStringHashCode(label));
}

/// Android values and key-name conversion supplied by the host.
///
/// Each value should be the corresponding Android `KeyEvent` Int value.
final class ShortcutPlatformValues {
  const ShortcutPlatformValues({
    required this.keyCodeSlash,
    required this.keyCodeEscape,
    required this.keyCode0,
    required this.metaCtrlOn,
    required this.metaAltOn,
    required this.metaShiftOn,
    required this.keyCodeFromString,
  });

  final int keyCodeSlash;
  final int keyCodeEscape;
  final int keyCode0;
  final int metaCtrlOn;
  final int metaAltOn;
  final int metaShiftOn;
  final int Function(String key) keyCodeFromString;
}

/// The host-independent fields used to construct Android
/// `KeyboardShortcutInfo`.
final class ShortcutInfoProjection {
  const ShortcutInfoProjection({
    required this.label,
    required this.keyCode,
    required this.modifierFlags,
  });

  final String label;
  final int keyCode;
  final int modifierFlags;

  @override
  bool operator ==(Object other) =>
      other is ShortcutInfoProjection &&
      other.label == label &&
      other.keyCode == keyCode &&
      other.modifierFlags == modifierFlags;

  @override
  int get hashCode => Object.hash(label, keyCode, modifierFlags);
}

int _getModifier(String modifier, ShortcutPlatformValues values) =>
    switch (modifier) {
      'Ctrl' => values.metaCtrlOn,
      'Alt' => values.metaAltOn,
      'Shift' => values.metaShiftOn,
      _ => 0,
    };

int _getKey(String key, ShortcutPlatformValues values) {
  if (key == '/') {
    return values.keyCodeSlash;
  }
  if (key == 'Esc') {
    return values.keyCodeEscape;
  }
  if (key.compareTo('0') >= 0 && key.compareTo('9') <= 0) {
    final parsed = _parseKotlinInt(key);
    if (parsed == null) {
      throw FormatException('Invalid integer: "$key"');
    }
    return _int32(values.keyCode0 + (parsed - 0));
  }
  return values.keyCodeFromString(key);
}

int _int32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}

int? _parseKotlinInt(String value) {
  if (value.isEmpty) return null;

  final codeUnits = value.codeUnits;
  var index = 0;
  var isNegative = false;
  if (codeUnits.first == 0x2B || codeUnits.first == 0x2D) {
    isNegative = codeUnits.first == 0x2D;
    index++;
  }
  if (index == codeUnits.length) return null;

  final limit = BigInt.from(isNegative ? 0x80000000 : 0x7FFFFFFF);
  var magnitude = BigInt.zero;
  for (; index < codeUnits.length; index++) {
    final digit = _unicode15DecimalDigitValue(codeUnits[index]);
    if (digit == null) return null;
    magnitude = magnitude * BigInt.from(10) + BigInt.from(digit);
    if (magnitude > limit) return null;
  }
  final result = isNegative ? -magnitude : magnitude;
  return result.toInt();
}

int? _unicode15DecimalDigitValue(int codeUnit) {
  for (final start in unicode15BmpDecimalDigitBlockStarts) {
    if (codeUnit < start) break;
    if (codeUnit < start + 10) return codeUnit - start;
  }
  return null;
}
