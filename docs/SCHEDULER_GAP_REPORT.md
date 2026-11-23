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

### Unit 77 — per-deck new-card candidates

`CollectionSqliteStorage.newCardCandidates()` reads queue-zero cards from one
explicit deck and returns Core's six new-card candidate fields. Caller-supplied
sorting supports lowest due position (`due ASC, ord ASC`), highest due position
(`due DESC, ord ASC`), random notes (`fnvhash(nid, salt), ord ASC`), and random
cards (`fnvhash(id, salt)`). Random modes require a u32 salt; IDs and mtime stay
signed 64-bit, ordinal is validated as u32, and SQLite row order is preserved.
This per-deck entry point does not choose active decks, prioritize gathering
across decks, admit daily limits, sort the post-gather queue, compose queues, or
execute the scheduler. Those remain separate scheduler work. Pinned source
hashes and AGPL attribution are recorded in
`packages/anki_collection_sqlite/NOTICE.md` and `SOURCE.sha256`.

### Unit 78 — active-deck new-card candidates

`CollectionSqliteStorage.activeNewCardCandidates()` reads queue-zero cards
from exactly the caller-supplied active deck IDs and returns the same six Core
new-card fields in the selected gather order. It supports lowest and highest
due position, random-note order with ordinal tie-breaking, and random-card
order using the caller's u32 salt. Empty input returns no rows; duplicate deck
IDs do not duplicate cards, and large active-deck sets avoid SQLite's
bind-variable limit while preserving SQL order. The method does not derive
active decks, prioritize gathering across decks, apply admission or daily
limits, sort the gathered queue, compose queues, or run the scheduler. Pinned
source hashes and AGPL attribution are recorded in
`packages/anki_collection_sqlite/NOTICE.md` and
`packages/anki_collection_sqlite/SOURCE.sha256`.

### Unit 79 — active-deck due review and interday-learning candidates

`CollectionSqliteStorage.dueCardCandidates()` reads review or interday-learning
cards from exactly the supplied active-deck IDs and applies Core's queue and
inclusive due-day cutoff. It returns Core's eight candidate fields, preserving
signed 64-bit IDs and mtime, applying i32/default-zero due conversion, and
validating reps as u32. The caller supplies deck order, queue kind, review
order, FSRS state, and scheduler timing. All Core review orders are represented,
including Deck/Day composites ranked by caller deck order, FSRS-specific ease
ordering, retrievability, relative overdueness, and the `fnvhash(id, mod)`
tie-breaker. Empty and duplicate deck inputs are handled without duplicate
candidates, and large sets use exact typed decimal literals instead of SQLite
bind variables. Active-deck derivation, configuration lookup, review/new
admission limits, gather stopping, queue mixing/sorting, counts, load balancing,
scheduler runtime, persistence, and UI remain outside this unit. Pinned source
hashes and AGPL provenance are recorded in the package notice and
`packages/anki_collection_sqlite/SOURCE.sha256`.

### Units 80–82 — load-balancer helpers

`anki_backend_models` now exposes Core's typed `EasyDay` classification,
seven-day percentage parsing, and pure reduced-day load normalization. The
helper takes explicit weekday indices and review counts and preserves Core's
Float32 and zip behavior. `CollectionSqliteStorage.deckTree()` already
implements the documented queue-count aggregation. Unit 81 adds
`IntervalLoadCandidate` and `calculateIntervalLoadWeight()`, which compute
Core's per-interval weight from explicit target interval, review count, sibling
modifier, and easy-day modifier using float32 arithmetic. Random weighted
selection, sibling search and modifier derivation, card-history reads, easy-day
configuration lookup, weekday/timezone derivation, and scheduler integration
remain outside the shared model unit. Pinned source hashes and AGPL provenance
are recorded in the package notice and
`packages/anki_backend_models/SOURCE.sha256`.

Unit 82 adds `calculateSiblingDayModifiers()`, a pure helper that applies the
Core five-day sibling neighborhood to explicit sibling day indices over an
inclusive window in Core's 99-day cache, preserving float32 factors and
multiplication rounding. It deduplicates indices and processes them in
ascending order for deterministic output. Sibling discovery, card-history reads, day/date
derivation, random weighted selection, and scheduler integration remain
outside; units 80–82 do not implement full load balancing.

### Unit 83 — collection-backed load-balancer due-card history

`CollectionSqliteStorage.getAllCardsDueInRange()` ports Core's card-history
input query for caller-supplied `[minDay, maxDay)` bounds. It returns one bucket
per day, includes cards from every queue and deck, preserves SQLite row order
within each bucket, and retains signed 64-bit card, note, and deck IDs. The
query enforces Core's u32 bounds and caps its span at the 99-day
`LOAD_BALANCE_DAYS` window; it does not derive the day range or combine history
with interval weights.
Parsed easy-day values from the stored config map are available in Unit 84;
deck-to-config resolution and weekday derivation, sibling discovery and
modifier inputs, random weighted selection, load-balancer orchestration, and
scheduler execution remain incomplete.

### Unit 84 — load-balancer preset config projection

`anki_backend_models.buildEasyDaysPercentages()` maps each stored deck-config
ID to its parsed seven-day `EasyDay` values, using the existing Core-compatible
empty-list default and invalid-length error behavior. It is a pure projection
over the stored config map: deck-to-config resolution, weekday/date derivation,
sibling search and modifier derivation, random weighted selection, and
scheduler orchestration remain incomplete. This helper does not integrate the
load balancer into the scheduler.

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
- Remaining scheduler work: random weighted interval selection, sibling
  search and modifier derivation, day/date derivation, deck-to-config
  resolution, and scheduler orchestration. Collection-backed due-card history
  input is available in Unit 83; `CollectionSqliteStorage.deckTree()` provides
  queue-count aggregation. The query and pure interval-weight/easy-day helpers
  do not complete full load balancing.
- Answer persistence, revlog mutation, undo, and collection transactions.
- Reviewer UI, navigation, timing, and platform IO.

These remain in the Core/backend or host adapter until their own shared Dart
units are implemented. This ledger describes the pure transition slice; it does
not claim scheduler execution or full review-session migration.
