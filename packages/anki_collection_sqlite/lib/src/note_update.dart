// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';

/// The reversible snapshot recorded for Anki Core's `Updated` note change.
///
/// This is an operation-boundary record. The collection package does not yet
/// own a generic undo stack that can consume it.
final class UpdatedNoteUndoRecord {
  UpdatedNoteUndoRecord(
    Note note, {
    required this.collectionMtimeMillis,
    required Iterable<String> addedTags,
  }) : oldNote = copyNote(note),
       addedTags = List.unmodifiable(addedTags);

  final Note oldNote;

  /// Prior `col.mod` value captured with Core's collection-level modified
  /// operation record.
  final Int64 collectionMtimeMillis;

  /// Tag rows registered by the update, corresponding to Core's
  /// `UndoableTagChange::Added` entries.
  final List<String> addedTags;
}

/// Result of updating an existing note using Core's edit semantics.
final class ExistingNoteUpdateResult {
  const ExistingNoteUpdateResult({
    required this.changed,
    required this.note,
    required this.addedCards,
    this.undoRecord,
  });

  final bool changed;
  final Note note;
  final List<Card> addedCards;
  final UpdatedNoteUndoRecord? undoRecord;
}

/// Makes a detached note snapshot suitable for an undo record.
Note copyNote(Note note) => Note(
  id: note.id,
  guid: note.guid,
  notetypeId: note.notetypeId,
  mtimeSecs: note.mtimeSecs,
  usn: note.usn,
  tags: note.tags,
  fields: note.fields,
  sortField: note.sortField,
  checksum: note.checksum,
);
