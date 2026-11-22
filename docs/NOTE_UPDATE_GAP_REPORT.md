# Collection undo/redo integration gaps

`CollectionSqliteStorage.updateExistingNote()` implements the Core-compatible
existing-note save and returns an `UpdatedNoteUndoRecord` containing the
original note, previous collection modification timestamp, and newly registered
tag names. Note updates now share the bounded 30-entry in-memory journal with
callback-backed collection operations. Eligible same-note edits coalesce within
Core's 60-second window when no card, tag, or config rows changed. Undo and redo
replay the note snapshot, generated cards, added tags, `nextPos` config, and
`col.mod` transactionally. A failed replay rolls back SQLite and restores the
journal entry. Writes through adapter mutation methods invalidate the journal;
direct substore writes and enclosing transactions must call
`discardExistingNoteUpdateUndoHistory()`.

The existing-note editor calls `updateExistingNote()`, so saves use Core's
no-op detection, normalized fields, tags, sync metadata, and missing
normal/Cloze card behavior. The Card Browser exposes note undo when a note edit
is the current top journal entry. Callback-backed Card Browser and Deck Picker
operations share the same global undo/redo ordering and may store an operation
label.

Undoable transactions capture SQLite changesets for primary-key tables and
classify row changes for cards, notes, decks, deck config, tags, revlogs,
collection config, notetypes, and custom tables. Exposed variants include
added, updated, removed, note tags, collection modification/schema changes,
and card/note/deck grave additions used by current operations. Deck deletion
retains its callback inverse for the keyless graves table. Custom restore
points can merge newer steps into a named entry. Card Browser and Deck Picker
feedback use localized operation labels and expose undo/redo actions for
deck creation, rename, removal, unbury, and the other journal-backed writes.

Remaining related work:

- Core queue answer/answer-undo entries and their Reviewer controls are owned
  by the later Scheduler/review-session unit; the Reviewer feedback projection
  is present here, but no Reviewer UI call site exists in this app yet.
- Extend source-derived coverage to other Core-only change variants when their
  corresponding operations are added to the shared collection layer.

This report describes known remaining scope; it does not claim full collection
undo/redo parity.
