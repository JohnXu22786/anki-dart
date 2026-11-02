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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// The ordered displayed and available samples for a Card Browser preview.
final class BrowserPreviewColumnProjection<T> {
  const BrowserPreviewColumnProjection({
    required this.displayed,
    required this.available,
  });

  final List<T> displayed;
  final List<T> available;
}

/// Splits preview [samples] by [currentColumns], ordering displayed samples by
/// each type's first current-column position and preserving sample order for
/// equal positions. Available samples retain their original order.
///
/// The host supplies already-resolved samples, columns, and the type lookup.
/// This projection does not create sample data or mutate either input.
BrowserPreviewColumnProjection<T> projectBrowserPreviewColumns<T, C>({
  required Iterable<T> samples,
  required Iterable<C> currentColumns,
  required C Function(T sample) columnTypeOf,
}) {
  final sampleList = List<T>.of(samples);
  final currentColumnList = List<C>.of(currentColumns);
  final displayed = <({int columnIndex, int sampleIndex, T sample})>[];
  final available = <T>[];

  for (var sampleIndex = 0; sampleIndex < sampleList.length; sampleIndex++) {
    final sample = sampleList[sampleIndex];
    final columnIndex = currentColumnList.indexOf(columnTypeOf(sample));
    if (columnIndex == -1) {
      available.add(sample);
    } else {
      displayed.add((
        columnIndex: columnIndex,
        sampleIndex: sampleIndex,
        sample: sample,
      ));
    }
  }

  displayed.sort((left, right) {
    final byColumn = left.columnIndex.compareTo(right.columnIndex);
    return byColumn != 0
        ? byColumn
        : left.sampleIndex.compareTo(right.sampleIndex);
  });

  return BrowserPreviewColumnProjection(
    displayed: displayed.map((entry) => entry.sample).toList(),
    available: available,
  );
}
