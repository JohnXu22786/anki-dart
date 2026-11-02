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
 * Source-derived from Fsrs.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// An FSRS library version with its source-mapped user-facing label.
final class FsrsVersion {
  const FsrsVersion(this.libraryVersion);

  /// The exact library version string supplied by the host.
  final String libraryVersion;

  /// The AnkiDroid label for a specifically supported library version.
  String? get displayString => switch (libraryVersion) {
    '0.6.4' => 'FSRS 4.5',
    '1.4.3' || '2.0.3' => 'FSRS 5',
    '4.1.1' || '5.1.0' || '5.2.0' || '6.3.0' || '6.6.2' => 'FSRS 6',
    _ => null,
  };

  @override
  String toString() => libraryVersion;

  @override
  bool operator ==(Object other) =>
      other is FsrsVersion && other.libraryVersion == libraryVersion;

  @override
  int get hashCode => libraryVersion.hashCode;
}
