// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/deck_picker.dart'
    show DeckPickerExportDeckRequest, DeckPickerExportFormat;

/// Executes the collection-backed portion of a typed Deck Picker text export.
/// The result is memory text; callers still own the platform file destination.
Future<CollectionTextExportResult> generateDeckPickerTextExport(
  CollectionSqliteStorage storage,
  DeckPickerExportDeckRequest request,
) {
  final cards = switch (request.format) {
    DeckPickerExportFormat.cards => true,
    DeckPickerExportFormat.notes => false,
    _ => throw ArgumentError.value(
      request.format,
      'request.format',
      'not a text export',
    ),
  };
  return storage.exportText(
    cards: cards,
    deckId: request.deckId,
    options: CollectionTextExportOptions(
      includeHtml: request.includeHtml,
      includeTags: !cards && request.includeTags,
      includeDeckName: !cards && request.includeDeckName,
      includeNotetypeName: !cards && request.includeNotetypeName,
      includeGuid: !cards && request.includeGuid,
    ),
  );
}
