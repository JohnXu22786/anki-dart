# Source and license notice

The shared review-queue primitives adapt `QueueEntry`, intraday learning
ordering, cutoff selection and learning-card requeue behavior from
`rslib/src/scheduler/queue/{entry.rs,learning.rs}`, and the two-list selection
ratio from `rslib/src/scheduler/queue/builder/intersperser.rs`, at the pinned
Anki Core commit below. Source digests are recorded in `SOURCE.sha256`. This
package slice is limited to deterministic entry mapping, sorting, cutoff
selection, requeue mechanics and queue interspersing with caller-supplied time
values. Collection-backed due selection, scheduler execution and counts,
load balancing, answer persistence and undo, and Reviewer UI remain outside
this boundary for later units.

`admitQueueCandidates()` also adapts Core's queue-builder gathering and limit
behavior from `rslib/src/scheduler/queue/builder/{gathering.rs,burying.rs,mod.rs}`,
`rslib/src/scheduler/queue/mod.rs`, and `rslib/src/decks/limits.rs`. It accepts
ordered, already gathered candidates, explicit scheduler timestamps, current
and parent deck capacities, and per-note bury modes. Previously gathered
intraday cards seed bury state without being added to this result. It admits
interday learning before reviews and new cards, shares review limits between
interday learning and reviews, accumulates sibling bury modes in source
encounter order, and preserves the sorted and by-deck new-card traversal stop
behavior. SQL
candidate queries and sorting, daily due-count calculation, load balancing,
collection-backed limit construction, and scheduler execution remain outside
this pure slice. It copies no upstream implementation.

This package ports Anki Core Card and Note domain values, protobuf conversions,
field checksum, field normalization, Note::fix_field_count, note preparation,
and HTML/media-aware field text behavior from `rslib/src/card/mod.rs`,
`rslib/src/card/service.rs`, `rslib/src/notes/mod.rs`, `rslib/src/storage/note/mod.rs`, and `rslib/src/text.rs`; duplicate Note first-field checks use the checksum-filtered storage query contract; note field validation and cloze parsing use `rslib/src/notes/mod.rs`, `rslib/src/cloze.rs`, `rslib/src/notetype/mod.rs`, `rslib/src/template.rs`, `rslib/src/text.rs`, and `proto/anki/notes.proto`.
field emptiness and Note field-presence behavior from `rslib/src/template.rs` and
`rslib/src/notes/mod.rs`; Notetype, NoteField
and CardTemplate values, conversions, and default configuration assets from
`rslib/src/notetype/mod.rs`, `rslib/src/notetype/service.rs`,
`rslib/src/notetype/fields.rs`, `rslib/src/notetype/templates.rs`,
`rslib/src/notetype/styling.css`, `rslib/src/notetype/cloze_styling.css`,
`rslib/src/notetype/header.tex`, `rslib/src/notetype/stock.rs`,
`rslib/src/image_occlusion/notetype.rs`, and
`rslib/src/image_occlusion/notetype.css`; Deck and DeckConfig values and
conversions from `rslib/src/decks/mod.rs`, `rslib/src/decks/name.rs`,
`rslib/src/decks/service.rs`, `rslib/src/deckconfig/mod.rs`, and
`rslib/src/deckconfig/service.rs`; RevlogId, RevlogEntry, review kind values,
protobuf conversions, and scheduling/statistics helpers from
`rslib/src/revlog/mod.rs`, `rslib/src/stats/service.rs`, and
`proto/anki/stats.proto`; media metadata values from `rslib/src/media/mod.rs`
and `rslib/src/sync/media/database/client/mod.rs`; and collection config entry
and scheduler version values from `rslib/src/config/mod.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The upstream source is
copyright Ankitects Pty Ltd and contributors and licensed under the GNU Affero
General Public License, version 3 or later. `SOURCE.sha256` records digests of
the exact upstream source files.

The package's Dart implementation is distributed under the same AGPL-3.0-or-
later license. Random-value constructors use an injected unsigned 64-bit
source so results remain deterministic and platform neutral:
`Note.newNote()` encodes a base91 GUID, while `NoteField.newField()` and
`CardTemplate.newTemplate()` assign the upstream random config IDs.
`Notetype.ankiDefault()`, `Notetype.defaultConfig()`, and
`Notetype.clozeConfig()` include the pinned default CSS and LaTeX header/footer
assets recorded in `SOURCE.sha256`. `StockNotetypeFactory` implements Anki
Core's Basic, Basic (type answer), Basic (and reversed), Basic (optional
reversed), Cloze, and Image Occlusion note types, while accepting translated
names from its caller. Image Occlusion collection operations and bundled
stock-name translation catalogs remain outside this slice. Field and template
name cleanup, NFC normalization, and duplicate-name suffixing follow the
pinned notetype sources. Name uniqueness uses full Unicode 12.1.0 case folding,
matching the generated table embedded by pinned `unicase 2.6.0`, from
`Unicode 12.1.0 CaseFolding.txt`; its digest is recorded in
`UNICODE_CASEFOLD.sha256` and the data is covered by the repository's Unicode
License V3 text at `LICENSES/Unicode-License-V3.txt`. Deck and DeckConfig models
include stored values, conversions, and pinned defaults. Media metadata and
collection configuration values are also included. `Note.prepareForUpdate()`
ports Anki Core's preparation sequence for field-count validation, field cleanup,
first-field checksum, and configured sort-field derivation. HTML field text
stripping preserves media filenames and follows Core's entity behavior. The
HTML named-entity table in `lib/src/html_entities.dart` is adapted from
`htmlescape` 0.3.1 by Viktor Dahl, licensed under Apache-2.0, MIT, or MPL-2.0;
the package includes the Apache-2.0 license text. Its source digest is recorded
in `THIRD_PARTY_SOURCE.sha256`. This package does not change the root `COPYING`
file. The field-empty predicate matches Anki Core's ASCII whitespace and empty
`br`/`div` tag syntax; `Note.nonEmptyFields()` pairs values to Notetype fields in
source order and returns a set of names, omitting values with no matching field.

The `Tag` value model follows `rslib/src/tags/mod.rs` at the pinned Anki Core commit; its SHA-256 is recorded in `SOURCE.sha256`.

`ReviewCardState.nextStates()` ports the review-state transition and interval
calculation from `rslib/src/scheduler/states/review.rs`, including the review
fuzz rules from `states/fuzz.rs` and the `LearningSteps` failure-delay inputs
from `states/steps.rs`. It accepts scheduler configuration and deterministic
fuzz. Hosts may supply FSRS next intervals/memory directly, or provide the
current memory state, elapsed days, desired retention, and exact parameters for
the pure FSRS 5.2.0 per-rating calculation. Queue construction, persistence,
parameter training, and answer execution remain host-owned. The per-card
memory-state calculation is described below.
The adaptation follows Anki Core commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`; exact source hashes are recorded in
`SOURCE.sha256`. Core is Copyright Ankitects Pty Ltd and contributors and is
licensed under AGPL-3.0-or-later. This package and the adaptation retain the
same license; root `COPYING` is unchanged.

`LearningCardState`, `NewCardState`, and `RelearningCardState` port Core's pure
Again/Hard/Good/Easy state calculations from
`rslib/src/scheduler/states/{learning.rs,relearning.rs,new.rs,normal.rs,steps.rs,mod.rs,fuzz.rs,review.rs}`
at the same pinned commit. Learning step arrays, review intervals, deterministic
fuzz, and FSRS next intervals/memory are explicit inputs. Queue construction,
answer persistence, FSRS calculation, and collection mutation remain outside
this package slice. The source files' hashes are recorded in `SOURCE.sha256`.

`computeFsrsMemoryState()` ports Core's per-card review-log projection,
truncated-history SM-2 starting-state inference, and memory-state calculation
from `rslib/src/scheduler/fsrs/memory_state.rs` and
`rslib/src/scheduler/fsrs/params.rs` at the pinned Anki Core commit. It follows
the `fsrs` 5.2.0 dependency pinned by that commit's `Cargo.lock` (crate SHA-256
`cab5f80c16d1d07e492a6828478ecb9f379f142ba6f19fa3b7955edd180ddc2e`), including
parameter defaults and legacy lengths, decay selection, parameter clipping,
FSRS recurrence, and its Float32 behavior. The mapped FSRS source files and Core
files are listed in `SOURCE.sha256`; the crate archive is recorded in
`THIRD_PARTY_SOURCE.sha256`. Anki Core remains Copyright Ankitects Pty Ltd and
contributors, licensed under AGPL-3.0-or-later. The adapted FSRS algorithm
source is Copyright Open Spaced Repetition and licensed under BSD-3-Clause;
its license text is included at `LICENSES/BSD-3-Clause-FSRS.txt`. This is only
the deterministic per-card calculation: FSRS parameter training, bulk updates,
collection and revlog queries, transactions, bulk rescheduling, queue
construction, and review-session orchestration remain host-owned. The
`computeFsrsNextStates()` and `computeFsrsNextInterval()` APIs compute only the
deterministic memory state and raw interval; interval limits, fuzz, and
short-term queue decisions stay with `ReviewCardState.nextStates()` and its
caller-supplied context.

`computeFsrsTrainingItems()` ports Core's training-mode revlog filtering and
FSRS-item projection from `rslib/src/scheduler/fsrs/params.rs`. It accepts
already grouped per-card histories and explicit cutoff/day-boundary timestamps,
then returns ordered review prefixes and Core's filtered-review count. This is
data preparation only: FSRS parameter optimization, collection queries,
progress reporting, and collection/card updates remain outside the package.
Training-item projections use the same pinned Core source and FSRS 5.2.0
provenance recorded above; no upstream implementation is copied into product
files.


The platform-neutral browser card-template renderer also follows Anki Core's
`rslib/src/template.rs`, `rslib/src/template_filters.rs`, `rslib/src/cloze.rs`,
`rslib/src/text.rs`, `rslib/src/browser_table.rs`,
`rslib/src/notetype/render.rs`, `rslib/src/notetype/templates.rs`,
`rslib/src/storage/card/mod.rs`, and
`rslib/src/card_rendering/{mod.rs,parser.rs,writer.rs}` at the same pinned
Anki Core commit. These files' SHA-256 digests are included in
`SOURCE.sha256`. Browser template failures and cases not represented by this
renderer return an explicit unavailable result; the app applies Core's
`html_to_text_line(..., true)` projection to successful rendered sides.
Missing selected cloze ordinals and Core-reported template errors are
represented as unavailable rows because this slice does not port Core's
localized template-rendering error catalogue. Incomplete handlebars that Core
tokenizes as literal text are preserved verbatim, matching Core's lexer.
