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

The last-deck setting remains the same JSON numeric value Core stores. When a
later card-generation path reads it, the adapter parses the stored decimal
directly into `Int64` rather than decoding it through a JavaScript number. A
fixture checks both the exact raw JSON digits and a subsequent lookup for a
deck ID above `2^53`.

## Boundaries still owned by the host or follow-up work

- AnkiDroid runs `fieldsCheck()` before invoking its add-note operation. This
  package operation intentionally does not port duplicate detection, empty
  first-field rules, cloze validation messages, image-occlusion messages, or
  other editor validation presentation. The current shared adapter forwards
  `fieldsCheck()` to its host callback; it does not implement backend checks.
- Deck picker state and host default-deck preference resolution remain outside
  the package. The caller passes the selected deck ID; a missing or filtered
  deck falls back to Core's normal default deck during card generation.
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
