# Cross-platform scheduler gap ledger

## Unit 25 — Core review-card transitions

`packages/anki_backend_models` now exposes a pure Dart review-card transition
calculation for Again, Hard, Good, and Easy. It follows Anki Core's early and
non-early review interval rules, ease/lapse/leech updates, interval bounds,
source fuzzing, and review-to-relearning choice. Core-provided FSRS next
intervals and memory states are explicit inputs. The calculation preserves
Float32 state and interval behavior and uses explicit 32-bit scheduling values.
Fixtures are in `packages/anki_backend_models/test/review_state_test.dart`.
Pinned source and license details are in `packages/anki_backend_models/NOTICE.md`
and `SOURCE.sha256`.

The root `ReviewScheduler` contract continues to forward the queue's opaque
scheduling snapshot and rating to its selected adapter. It does not persist the
transition or add collection access; an adapter can supply transition inputs
from Core and use the shared calculation while retaining its backend answer
operation.

## Remaining scheduler work

### Unit 74 — queue candidate admission

`anki_backend_models.admitQueueCandidates()` admits caller-supplied day-learning
(interday learning), review, and new-card sequences in Core gather order. It
accepts Unit73's already gathered intraday candidates as bury-state seeds while
leaving those cards in Unit73's existing queue output. It applies separate
root and non-root current/parent deck limits, accumulates each note's bury modes
as siblings are encountered, and preserves the distinct sorted and by-deck new
gather stop behavior. It also models Core's configurable review-to-new limit
coupling for root and each deck/ancestor. Scheduler timestamps, candidate order,
deck ancestry and limits, limit-coupling policy, and per-candidate bury modes
are explicit inputs. Collection candidate
queries and sorting, intraday learning selection, due counts, load balancing,
and scheduler execution remain outside this slice. Pinned source hashes and
AGPL attribution are recorded in `packages/anki_backend_models/NOTICE.md` and
`SOURCE.sha256`.

### Unit 75 — new-card sorting and main-queue composition

`anki_backend_models.sortNewQueueCandidates()` implements Core's five
new-card sort orders over already gathered candidates, including salted FNV
ordering from exact signed 64-bit card/note IDs. `composeMainQueue()` maps
reviews and interday learning to their distinct main-queue entry kinds, then
applies Core's interday-learning/review mix and new-card/main-queue mix as
separate stages. Candidate gather order and both mix policies are explicit
inputs; sorting ties preserve input order. Intraday learning, SQL gathering and
sorting, queue counts, scheduler configuration lookup, load balancing, and
scheduler execution remain outside this pure slice. Pinned source hashes and
AGPL attribution are recorded in the package notice and `SOURCE.sha256`.

### Unit 76 — collection-backed intraday learning candidates

`CollectionSqliteStorage.intradayLearningCandidates()` reads candidate rows
from the collection for caller-supplied active deck IDs and `learnCutoff`
seconds. It selects only cards in those decks with queue code 1 (Learning) or
4 (PreviewRepeat) and `due <= learnCutoff`, projecting card ID, note ID, due
seconds, integer-cast modification seconds, current deck ID, original deck ID,
and reps. IDs and modification seconds retain signed 64-bit precision; due is
an i32 with Core's default-zero handling when its row conversion fails, and
reps is checked as u32. Each matching database row is returned once in
SQLite's natural query order; empty deck input returns an empty list.
Intraday sort and learn-ahead filtering, Unit74 bury-state resolution, review
and interday/new queries, counts, active deck construction, scheduler runtime,
persistence, and UI remain outside this boundary. Core source hashes and AGPL
provenance are recorded in `packages/anki_collection_sqlite/NOTICE.md` and
`SOURCE.sha256`.

- New-card, learning-card, and existing relearning-card pure Again/Hard/Good/Easy
  transitions are now exposed by `NewCardState`, `LearningCardState`, and
  `RelearningCardState` in `anki_backend_models`. Learning-step minutes,
  graduation intervals, deterministic fuzz, and FSRS next states are supplied
  explicitly. Source hashes and AGPL attribution are in the package notice and
  `SOURCE.sha256`.
- FSRS parameter training and next-state calculation.
- FSRS memory-state derivation now has a pure per-card model in
  `anki_backend_models.computeFsrsMemoryState()`. It takes ordered revlogs,
  parameters, historical retention, cutoff, and the next-day timestamp as
  explicit inputs. Parameter training, collection queries, bulk writes,
  transactions, and rescheduling remain host-owned.
- Remaining queue work: SQL candidate queries, daily counts, load
  balancing, and collection-backed scheduler configuration reads.
- Answer persistence, revlog mutation, undo, and collection transactions.
- Reviewer UI, navigation, timing, and platform IO.

These remain in the Core/backend or host adapter until their own shared Dart
units are implemented. This ledger describes the pure transition slice; it does
not claim scheduler execution or full review-session migration.
