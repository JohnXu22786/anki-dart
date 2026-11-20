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
 * Source-derived from ExportDialogFragment.kt and dialog_export_options.xml in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:fixnum/fixnum.dart';

/// Export controls available for a format.
enum DeckPickerExportOption {
  includeScheduling,
  includeDeckConfigs,
  includeMedia,
  includeLegacy,
  includeHtml,
  includeTags,
  includeDeckName,
  includeNotetypeName,
  includeGuid,
}

/// The four formats, selector order, and source-defined option visibility.
enum DeckPickerExportFormat {
  collection,
  apkg,
  notes,
  cards;

  Set<DeckPickerExportOption> get visibleOptions => switch (this) {
    collection => const {
      DeckPickerExportOption.includeMedia,
      DeckPickerExportOption.includeLegacy,
    },
    apkg => const {
      DeckPickerExportOption.includeScheduling,
      DeckPickerExportOption.includeDeckConfigs,
      DeckPickerExportOption.includeMedia,
      DeckPickerExportOption.includeLegacy,
    },
    notes => const {
      DeckPickerExportOption.includeHtml,
      DeckPickerExportOption.includeTags,
      DeckPickerExportOption.includeDeckName,
      DeckPickerExportOption.includeNotetypeName,
      DeckPickerExportOption.includeGuid,
    },
    cards => const {DeckPickerExportOption.includeHtml},
  };
}

/// Initial control values and visibility for a format.
final class DeckPickerExportOptions {
  const DeckPickerExportOptions({
    this.includeScheduling = false,
    this.includeDeckConfigs = false,
    this.includeMedia = false,
    this.includeLegacy = false,
    this.includeHtml = false,
    this.includeTags = false,
    this.includeDeckName = false,
    this.includeNotetypeName = false,
    this.includeGuid = false,
  });

  final bool includeScheduling;
  final bool includeDeckConfigs;
  final bool includeMedia;
  final bool includeLegacy;
  final bool includeHtml;
  final bool includeTags;
  final bool includeDeckName;
  final bool includeNotetypeName;
  final bool includeGuid;

  factory DeckPickerExportOptions.defaultsFor(DeckPickerExportFormat format) =>
      switch (format) {
        DeckPickerExportFormat.collection => const DeckPickerExportOptions(
          includeMedia: true,
        ),
        DeckPickerExportFormat.apkg => const DeckPickerExportOptions(
          includeScheduling: true,
          includeMedia: true,
        ),
        DeckPickerExportFormat.notes => const DeckPickerExportOptions(
          includeHtml: true,
          includeTags: true,
        ),
        DeckPickerExportFormat.cards => const DeckPickerExportOptions(
          includeHtml: true,
        ),
      };

  DeckPickerExportOptions copyWith({
    bool? includeScheduling,
    bool? includeDeckConfigs,
    bool? includeMedia,
    bool? includeLegacy,
    bool? includeHtml,
    bool? includeTags,
    bool? includeDeckName,
    bool? includeNotetypeName,
    bool? includeGuid,
  }) => DeckPickerExportOptions(
    includeScheduling: includeScheduling ?? this.includeScheduling,
    includeDeckConfigs: includeDeckConfigs ?? this.includeDeckConfigs,
    includeMedia: includeMedia ?? this.includeMedia,
    includeLegacy: includeLegacy ?? this.includeLegacy,
    includeHtml: includeHtml ?? this.includeHtml,
    includeTags: includeTags ?? this.includeTags,
    includeDeckName: includeDeckName ?? this.includeDeckName,
    includeNotetypeName: includeNotetypeName ?? this.includeNotetypeName,
    includeGuid: includeGuid ?? this.includeGuid,
  );
}

/// Typed request sent through the platform-neutral Deck Picker export callback.
///
/// A null [deckId] represents All decks for APKG and text exports, and the
/// whole collection for collection export. File generation and delivery belong
/// to the host export service.
final class DeckPickerExportDeckRequest {
  const DeckPickerExportDeckRequest({
    required this.deckId,
    required this.format,
    required this.options,
  });

  final Int64? deckId;
  final DeckPickerExportFormat format;
  final DeckPickerExportOptions options;

  bool get includeScheduling => options.includeScheduling;
  bool get includeDeckConfigs => options.includeDeckConfigs;
  bool get includeMedia => options.includeMedia;
  bool get includeLegacy => options.includeLegacy;
  bool get includeHtml => options.includeHtml;
  bool get includeTags => options.includeTags;
  bool get includeDeckName => options.includeDeckName;
  bool get includeNotetypeName => options.includeNotetypeName;
  bool get includeGuid => options.includeGuid;
}

/// Projects the selected export dialog values to a host-facing request.
///
/// The deck ID remains an [Int64] end to end. A stale or All decks selection is
/// represented by `null`, which leaves the export limit unrestricted.
DeckPickerExportDeckRequest projectDeckPickerExportDeck({
  required int legacyDeckId,
  Int64? exactDeckId,
  DeckPickerExportFormat format = DeckPickerExportFormat.apkg,
  DeckPickerExportOptions? options,
  bool allDecks = false,
}) => DeckPickerExportDeckRequest(
  deckId: allDecks ? null : exactDeckId ?? Int64(legacyDeckId),
  format: format,
  options: options ?? DeckPickerExportOptions.defaultsFor(format),
);
