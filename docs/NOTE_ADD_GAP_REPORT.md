# Collection add-note operation gap report

`CollectionSqliteStorage.addNoteToDeck()` now provides the atomic collection
operation that a shared new-note editor can call after choosing a deck. It
prepares and inserts the supplied unsaved note, registers canonical tags,
generates normal or Cloze cards, updates collection config and `col.mod`, and
returns the generated-card count together with source-shaped `OpChanges`.
The caller must resolve the selected/default deck before calling; the method
uses that exact selected ID for Core's last-deck and last-notetype settings.

The operation has source-derived coverage for configured field normalization,
tag normalization/case/deduplication, local note metadata, normal template
order, Cloze ordinals, custom and default deck selection, invalid selected
deck fallback, Core's ordinal-zero fallback for an otherwise empty normal
note, config updates, 64-bit note/card/deck IDs, and rollback after card or
config failures. All SQL writes run under one savepoint. Missing notetypes,
deck configuration failures, SQL errors, and card-generation failures
propagate and roll back the note, generated cards, tags, `nextPos`, operation
config, and collection mtime.

Those rollback guarantees apply to operation errors before the savepoint is
released. The injected driver's async flush runs after the SQLite commit; if
that flush fails, the future reports a post-commit error while the complete
operation remains in the database. Callers must re-read/reconcile before
retrying after that error. The new-note editor keeps its in-memory draft,
retries the driver's pending flush, and then persists any later field/tag
edits through the existing note-update operation; it does not repeat the
committed add operation. Other callers must explicitly reconcile the
collection state before retrying.

The last-deck setting remains the same JSON numeric value Core stores. When a
later card-generation path reads it, the adapter parses the stored decimal
directly into `Int64` rather than decoding it through a JavaScript number. A
fixture checks both the exact raw JSON digits and a subsequent lookup for a
deck ID above `2^53`.

## Shared cross-platform Note Editor flow

`apps/anki/lib/note_editor_screen.dart` now supports a new-note mode alongside
existing-note editing. The Card Browser toolbar exposes Add when its controller
implements `CardBrowserNewNoteEditorController`; the collection controller
creates an empty Core `Note`, supplies the chosen notetype and deck IDs through
`NewNoteEditorDraft`, and calls the Unit38 `addNoteToDeck()` operation after
validation. The shared field and tag UI is used on all Flutter targets.

The new-note host validates through the existing
`anki_backend_models.noteFieldsCheck()` implementation and projects its
generated state through `projectNoteFieldsCheckResult()`. Its precedence and
message mapping follow Core and AnkiDroid: invalid Cloze note type/field states
precede first-field emptiness; an empty first field precedes missing Cloze and
duplicate checks; `DUPLICATE` is a successful validation state; unknown states
fail without a specific message. Validation or storage errors leave field and
tag edits in the editor. A successful add reports Unit38's generated card
count and loads a fresh empty draft; leaving the editor refreshes the browser's
active search while preserving its selected rows.

New notes initially use the current deck's legacy `mid` value when that
notetype exists, then `curModel`, Basic, or the first available type. The
initial destination deck follows this priority: a valid explicit Deck Picker
choice; the valid regular deck remembered by an initialized Card Browser; then
the collection add-to-current-deck preference and per-type remembered deck,
falling back to the current deck or Default when invalid. The browser's
separate AnkiDroid `lastDeckId` is persisted as an exact decimal string and
passed automatically when Add Note comes from an initialized browser. The All
Decks sentinel and missing, deleted, malformed, or filtered browser IDs use
the fallback; an uninitialized Deck Picker current-deck route ignores browser
state. Selecting a note type updates `curModel` and the current deck's legacy
`mid`, refreshes fields while preserving compatible entered values and tags,
and applies that type's remembered destination deck when valid; otherwise the
current draft's selected deck remains selected.

## Boundaries still owned by the host or follow-up work

- Image Occlusion field setup and its special empty-field message remain out
  of this editor flow; the app maps ordinary new-note validation only.
- The shared new-note editor now provides both a regular-deck selector and a
  note-type selector. Both preserve exact 64-bit IDs. The deck selector shows
  nested names, filters larger catalogs, changes only the in-memory draft, and
  prevents saving to a missing or newly filtered deck. The note-type selector
  sorts visible types by name and updates the draft's field labels, compatible
  values, validation, generated cards, `curModel`, and current deck `mid`.
  Existing-note conversion, Image Occlusion setup, template/media editing, and
  full notetype management remain separate follow-up flows.
- Core `transact(Op::AddNote)` records note/card/tag/config/collection undo
  payloads and returns operation changes. This method returns `OpChanges` and
  does not create a generic undo journal or an operation-specific history.
- The adapter is client-side and uses `usn = -1` for local writes, as do its
  existing editor mutations. A server-mode collection would need to supply its
  current sync sequence before claiming server parity.
- Core guarantees at least one card for a new note by generating ordinal 0
  when no normal template matches. Consequently, a zero-card `AddNote` result
  is not a Core-compatible outcome for this operation.

Focused fixtures are in
`packages/anki_collection_sqlite/test/add_note_operation_test.dart`. Source
hashes and licensing attribution are recorded in the package's
`SOURCE.sha256` and `NOTICE.md`; root `COPYING` is unchanged.
