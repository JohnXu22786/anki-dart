/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ProfileId.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'dart:math';

/// A type-safe profile identifier.
final class ProfileId {
  const ProfileId(this.value);

  /// Reserved identifier for the default profile.
  static const defaultId = ProfileId('default');

  /// The original identifier string, preserved without normalization.
  final String value;

  /// Whether this identifier is exactly the default identifier.
  bool get isDefault => value == defaultId.value;

  /// Generates an ID from the first four random bytes of a UUIDv4-shaped value.
  ///
  /// The first eight hexadecimal digits of Java's UUIDv4 contain four fully
  /// random bytes; the fixed UUID version and variant bits occur later.
  static ProfileId generate() {
    final random = Random.secure();
    final digits = List.generate(
      4,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return ProfileId('p_$digits');
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is ProfileId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
