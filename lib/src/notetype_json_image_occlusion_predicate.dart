/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts the pinned `NotetypeJson.isImageOcclusion` computed getter.
///
/// The host supplies its `originalStockKind` property, the source constant, and
/// a predicate identifying the host's source-equivalent `JSONException` class.
/// JSON access and exception types remain host-owned.
final class NotetypeJsonImageOcclusionPredicate {
  const NotetypeJsonImageOcclusionPredicate({
    required int Function() originalStockKind,
    required int originalStockKindImageOcclusionValue,
    required bool Function(Object error) isSourceJsonException,
  }) : _originalStockKind = originalStockKind,
       _originalStockKindImageOcclusionValue =
           originalStockKindImageOcclusionValue,
       _isSourceJsonException = isSourceJsonException;

  final int Function() _originalStockKind;
  final int _originalStockKindImageOcclusionValue;
  final bool Function(Object error) _isSourceJsonException;

  /// Whether the host stock-kind value equals its image-occlusion constant.
  ///
  /// Only errors identified by [isSourceJsonException] become `false`; all
  /// other callback errors are rethrown unchanged.
  bool get isImageOcclusion {
    try {
      return _originalStockKind() == _originalStockKindImageOcclusionValue;
    } on Object catch (error) {
      if (_isSourceJsonException(error)) return false;
      rethrow;
    }
  }
}
