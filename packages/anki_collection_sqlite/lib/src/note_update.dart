// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';

/// The reversible snapshot recorded for Anki Core's `Updated` note change.
///
/// This is an operation-boundary record consumed by the scoped note-update
/// history. The collection package does not yet provide a generic undo stack.
final class UpdatedNoteUndoRecord {
  UpdatedNoteUndoRecord(
    Note note, {
    required this.collectionMtimeMillis,
    this.nextCardPositionConfigBefore,
    this.nextCardPositionConfigAfter,
    required Iterable<String> addedTags,
  }) : oldNote = copyNote(note),
       addedTags = List.unmodifiable(addedTags);

  final Note oldNote;

  /// Prior `col.mod` value captured with Core's collection-level modified
  /// operation record.
  final Int64 collectionMtimeMillis;

  /// Exact prior `nextPos` config row, or null if it was not present.
  final ExistingNoteUpdateConfigSnapshot? nextCardPositionConfigBefore;

  /// Exact resulting `nextPos` config row, or null if it remains absent.
  final ExistingNoteUpdateConfigSnapshot? nextCardPositionConfigAfter;

  /// Tag rows registered by the update, corresponding to Core's
  /// `UndoableTagChange::Added` entries.
  final List<String> addedTags;
}

/// Exact `config` row snapshot used to undo Core's next-card-position update.
final class ExistingNoteUpdateConfigSnapshot {
  ExistingNoteUpdateConfigSnapshot({
    required this.key,
    required this.usn,
    required this.mtimeSecs,
    required Iterable<int> value,
  }) : value = List.unmodifiable(value);

  final String key;
  final int usn;
  final Int64 mtimeSecs;
  final List<int> value;
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

/// Availability of the note-update-only history in one open SQLite storage.
/// This does not report generic collection undo/redo support.
final class ExistingNoteUpdateUndoStatus {
  const ExistingNoteUpdateUndoStatus({
    required this.canUndo,
    required this.canRedo,
    required this.lastStep,
  });

  final bool canUndo;
  final bool canRedo;
  final int lastStep;
}
