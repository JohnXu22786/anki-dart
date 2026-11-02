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
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ProfileItem.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'profile_id.dart';

/// Host implementation of AnkiDroid's `String.firstGraphemeOrNull()`.
///
/// Android hosts can provide the pinned `BreakIterator` implementation,
/// preserving platform Unicode segmentation instead of substituting a Dart
/// segmentation algorithm.
typedef FirstGraphemeOrNull = String? Function(String value);

/// UI model for one row in AnkiDroid's profile list.
final class ProfileItem {
  const ProfileItem({required this.id, required this.name});

  final ProfileId id;
  final String name;

  /// Uppercases the host-supplied first grapheme, or returns `?` when absent.
  String initial({required FirstGraphemeOrNull firstGraphemeOrNull}) =>
      firstGraphemeOrNull(name)?.toUpperCase() ?? '?';

  @override
  bool operator ==(Object other) =>
      other is ProfileItem && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
