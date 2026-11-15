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
 * Behavioral reference: ChangeNoteTypeViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// A value selected when mapping a field or template during note-type changes.
sealed class SelectedIndex {
  const SelectedIndex();

  /// The singleton choice that discards the mapped field or template.
  static const SelectedIndex nothing = _SelectedIndexNothing();

  /// Creates an index selection without validating or normalizing [index].
  factory SelectedIndex.from(int index) = SelectedIndexValue;

  /// Converts the selection to the nullable ordinal used by the host map.
  int? toNullableInt() => switch (this) {
    _SelectedIndexNothing() => null,
    SelectedIndexValue(:final index) => index,
  };
}

final class _SelectedIndexNothing extends SelectedIndex {
  const _SelectedIndexNothing();
}

/// The source's value-equal `Index(index)` selection.
final class SelectedIndexValue extends SelectedIndex {
  const SelectedIndexValue(this.index);

  final int index;

  @override
  bool operator ==(Object other) =>
      other is SelectedIndexValue && other.index == index;

  @override
  int get hashCode => Object.hash(runtimeType, index);
}
