# Existing note update integration gaps

`CollectionSqliteStorage.updateExistingNote()` implements the Core-compatible
existing-note save and returns an `UpdatedNoteUndoRecord` containing the
original note, previous collection modification timestamp, and newly registered
tag names. The storage layer also keeps up to 30 in-memory, note-update-only
undo steps. Successive edits to the same note coalesce within Core's 60-second
window when no card, tag, or config rows changed. Undo and redo atomically
replay the note snapshot, generated cards, added tags, `nextPos` config, and
`col.mod`. Writes
through the adapter's async mutation methods clear that scoped history; direct
substore writes and enclosing transactions must call
`discardExistingNoteUpdateUndoHistory()`.

The existing-note editor in PR #101 now calls `updateExistingNote()`, so saves
use the Core behavior for no-op detection, normalized fields, tags, sync
metadata, and missing normal/Cloze cards. The editor still does not expose the
note-update history through an undo/redo control.

Remaining work:

- Add the generic collection operation journal Core provides for other undoable
  changes, including cards, notes, decks, tags, revlogs, config, custom steps,
  undo/redo merging, and status labels.
- Wire undo/redo status and actions into the shared app flow and match AnkiDroid
  menu/Reviewer behavior across all six supported targets.
- Confirm behavior when an operation is nested in a larger collection
  transaction; the current adapter scope is a standalone editor save.

This report describes known remaining scope; it does not claim full collection
undo/redo parity.
