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
 * Source-derived from ShortcutGroup.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'shortcut_projection.dart';

/// A source shortcut group with its Android string resource ID.
///
/// The host supplies resource lookup and constructs
/// `KeyboardShortcutGroup` from [ShortcutGroupProjection].
final class ShortcutGroup {
  const ShortcutGroup({required this.shortcuts, required this.id});

  final List<Shortcut> shortcuts;
  final int id;

  /// Projects each shortcut in order, then resolves this group's title.
  ///
  /// Shortcut conversion failures stop the mapping and prevent title lookup.
  /// Resource lookup failures propagate unchanged.
  ShortcutGroupProjection toShortcutGroup(
    ShortcutPlatformValues values, {
    required String Function(int resourceId) resolveTitle,
  }) {
    final projections = shortcuts
        .map((shortcut) => shortcut.toShortcutInfo(values))
        .toList();
    final groupLabel = resolveTitle(id);
    return ShortcutGroupProjection(label: groupLabel, shortcuts: projections);
  }

  @override
  bool operator ==(Object other) =>
      other is ShortcutGroup &&
      other.id == id &&
      _shortcutListEquals(other.shortcuts, shortcuts);

  @override
  int get hashCode => _int32(31 * _shortcutListHashCode(shortcuts) + id);
}

/// The host-independent result used to construct Android
/// `KeyboardShortcutGroup`.
final class ShortcutGroupProjection {
  const ShortcutGroupProjection({required this.label, required this.shortcuts});

  final String label;
  final List<ShortcutInfoProjection> shortcuts;

  @override
  bool operator ==(Object other) =>
      other is ShortcutGroupProjection &&
      other.label == label &&
      _shortcutInfoListEquals(other.shortcuts, shortcuts);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(shortcuts));
}

bool _shortcutListEquals(List<Shortcut> left, List<Shortcut> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _shortcutInfoListEquals(
  List<ShortcutInfoProjection> left,
  List<ShortcutInfoProjection> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

int _shortcutListHashCode(List<Shortcut> shortcuts) {
  var result = 1;
  for (final shortcut in shortcuts) {
    result = _int32(31 * result + shortcut.hashCode);
  }
  return result;
}

int _int32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
