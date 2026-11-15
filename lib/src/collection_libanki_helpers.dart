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
 * Behavioral reference: Collection.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Flattens each empty-card report's card IDs in report and source order.
///
/// This adapts `EmptyCardsReport.emptyCids()` without depending on the generated
/// protocol type. The host constructs reports and supplies their card-ID lists.
List<int> flattenEmptyCardIds(Iterable<Iterable<int>> cardIdsByReport) =>
    cardIdsByReport.expand((cardIds) => cardIds).toList();

/// Returns a fresh ascending list of cloze ordinals supplied by the backend.
///
/// This adapts the deterministic sorting step in
/// `Collection.clozeNumbersInNote()`; the host owns note conversion and the
/// backend's cloze-number extraction.
List<int> sortClozeOrdinals(Iterable<int> backendOrdinals) =>
    backendOrdinals.toList()..sort();

/// Returns whether the schema modification timestamp is newer than last sync.
///
/// This adapts `Collection.schemaChanged()` while leaving both DB reads to the
/// host. The source reads the schema timestamp before the last-sync timestamp.
bool collectionSchemaChanged({
  required int Function() readSchemaModified,
  required int Function() readLastSync,
}) {
  final schemaModified = readSchemaModified();
  final lastSync = readLastSync();
  return schemaModified > lastSync;
}
