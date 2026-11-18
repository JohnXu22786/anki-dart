# Existing note update integration gaps

The shared `CollectionSqliteStorage.updateExistingNote()` operation now
implements Core-compatible existing-note save behavior and returns an
`UpdatedNoteUndoRecord` containing the original note plus prior `col.mod`.
The record also lists tag rows newly registered by the operation, matching
Core's separate `UndoableTagChange::Added` entries.
Focused operation and random-position tests cover note no-op detection,
metadata, configured NFC, tag canonicalization, normal and cloze card
generation, target-deck selection/fallback, 64-bit card IDs, and rollback.
Normal card generation parses question templates directly, and calls to this
operation are serialized per storage instance. The savepoint body contains no
`await`; it performs synchronous SQLite writes and flushes after release, so
other low-level storage calls cannot be captured by or rolled back with this
operation.

Two application integration steps remain:

- Unit33's Note Editor save path must call `updateExistingNote()` instead of
  writing the note row directly. Until that current-main follow-up is merged,
  the UI save path can still bypass metadata and card generation.
- The application has no generic shared collection undo/redo journal or replay
  API. The returned record contains the Core `Updated` note and collection
  modification snapshots, but an end-user undo affordance is incomplete until
  the editor records and replays it through that application history.

The Unit34 implementation does not change Unit33 or PR #101. Keep that PR in
draft until the new operation is integrated and the full end-to-end gates pass.
