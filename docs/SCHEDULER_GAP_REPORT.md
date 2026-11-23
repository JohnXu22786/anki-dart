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
selection was outside Unit 81's scope and is now provided by Unit 87.
Card-history reads, easy-day configuration lookup, weekday/timezone derivation,
and scheduler integration remain outside the shared model unit. Pinned source
hashes and AGPL provenance are recorded in the package notice and
`packages/anki_backend_models/SOURCE.sha256`.

Unit 82 adds `calculateSiblingDayModifiers()`, a pure helper that applies the
Core five-day sibling neighborhood to explicit sibling day indices over an
inclusive window in Core's 99-day cache, preserving float32 factors and
multiplication rounding. It deduplicates indices and processes them in
ascending order for deterministic output. Unit 82 did not include weighted
selection, which Unit 87 now provides. Sibling discovery, card-history reads,
day/date derivation, and scheduler integration remain outside; units 80–82 do
not implement full load balancing.

### Unit 83 — collection-backed load-balancer due-card history

`CollectionSqliteStorage.getAllCardsDueInRange()` ports Core's card-history
input query for caller-supplied `[minDay, maxDay)` bounds. It returns one bucket
per day, includes cards from every queue and deck, preserves SQLite row order
within each bucket, and retains signed 64-bit card, note, and deck IDs. The
query enforces Core's u32 bounds and caps its span at the 99-day
`LOAD_BALANCE_DAYS` window; it does not derive the day range or combine history
with interval weights.
Parsed easy-day values from the stored config map are available in Unit 84;
weighted selection is now available in Unit 87. Deck-to-config resolution and
weekday derivation, sibling discovery and modifier inputs, load-balancer
orchestration, and scheduler execution remain incomplete.

### Unit 84 — load-balancer preset config projection

`anki_backend_models.buildEasyDaysPercentages()` maps each stored deck-config
ID to its parsed seven-day `EasyDay` values, using the existing Core-compatible
empty-list default and invalid-length error behavior. It is a pure projection
over the stored config map: deck-to-config resolution, weekday/date derivation,
sibling search and modifier derivation, and scheduler orchestration remain
incomplete. Unit 87 now supplies weighted selection separately. This helper
does not integrate the load balancer into the scheduler.

### Unit 85 — load-balancer day sibling state

`LoadBalancerDay` tracks caller-supplied card/note pairs and the set of notes
present on one day, porting Core's in-memory add, remove, and sibling-membership
operations. Removing a card clears its note membership only after the last card
for that note is removed. Cross-day sibling search, day/time derivation, and
scheduler integration remain incomplete; weighted selection is now available
in Unit 87.

### Unit 86 — cross-preset sibling-day search

`calculateSiblingModifiers()` searches the 99 day buckets supplied for every
deck-config preset and finds all days containing the nullable selected note.
It deduplicates day indices across presets, sorts them deterministically, and
delegates the five-day factors to Unit 82's `calculateSiblingDayModifiers()`.
Each preset bucket is validated to contain exactly Core's 99 cached days.
Sibling search across presets is now available as a pure model helper. Unit 87
also supplies weighted random selection; date and weekday derivation and
scheduler orchestration remain incomplete. This does not implement full load
balancing.

### Unit 87 — seeded weighted interval selection

`anki_backend_models.selectWeightedInterval()` now selects from ordered
`IntervalLoadCandidate` values using Core's Float32 weights and the pinned
rand 0.9.4 `WeightedIndex<f32>` behavior. Its seed expansion and ChaCha12
stream match rand_core 0.9.3 and rand_chacha 0.9.0 for nullable unsigned
64-bit seeds on VM and Web. This is a pure shared helper; load-balancer
orchestration, preset storage/configuration integration, date and weekday
derivation, and scheduler wiring remain incomplete.

### Unit 88 — load-balancer weekday projection

`anki_backend_models.intervalToWeekday()` ports Core's interval-to-weekday
projection from the pinned load-balancer source. It applies the interval's
whole-second offset to the absolute `nextDayAt` timestamp and then projects the
target timestamp into the machine's local timezone to return a Monday-based
weekday index. It validates the nonzero u32 interval domain and rejects
unrepresentable target timestamps. Full timezone/date scheduling context,
preset storage/configuration integration, load-balancer orchestration, and
scheduler wiring remain open; this helper does not implement full load
balancing.

### Unit 89 — pure load-balancer interval decision

`anki_backend_models.findLoadBalancedInterval()` composes Core's pinned
`LoadBalancer::find_interval()` path with the existing constrained fuzz-bound,
easy-day, weekday, sibling, load-weight, and seeded-selection helpers. It
accepts caller-preloaded 99-day caches and seven-day easy-day values keyed by
preset, plus the absolute `nextDayAt` timestamp, selected preset, nullable
note, interval bounds, and optional seed. Its decision is pure and does not
read or mutate collection state. Card-history reads/input assembly,
preset/deck resolution, timezone/date input construction, cache mutation,
collection storage, scheduler wiring, answer/reviewer UI, and full
cross-platform review integration remain incomplete.

### Unit 90 — initial load-balancer cache construction

`anki_backend_models.LoadBalancerCache.fromHistory()` ports the pure grouping
portion of Core `LoadBalancer::new()`. Given 99 ordered card-history buckets,
a caller-provided deck-to-config map, and the stored config map, it groups
card/note pairs into 99-day preset caches and projects easy-day settings for
all configs. Cards without a deck mapping are skipped as in Core; presets with
no mapped cards have no day-cache entry. Deriving the day window and
deck-to-config mapping, persisted scheduling changes, scheduler call-site
integration, answer persistence, Reviewer UI, and full cross-platform review
integration remain incomplete.

### Unit 91 — load-balancer cache mutation

`LoadBalancerCache.addCard()` updates one existing preset/day bucket when its
indices are in range. `removeCard()` searches all preset buckets and days by
card ID; a day retains note membership while another card for that note remains.
These are in-memory cache updates only. Persisted scheduling changes, storage
queries, scheduler call-site wiring, answer/reviewer UI, and full cross-platform
review integration remain incomplete.

### Unit 92 — collection-backed load-balancer cache

`CollectionSqliteStorage.buildLoadBalancerCache()` reads the existing 99-day
due-card history range, loads all stored deck configs, and combines them with
the caller-supplied collection day and deck-to-config map through
`LoadBalancerCache.fromHistory()`. It preserves the source query's all-queue
history and groups each day by preset. Unit 93 adds
`buildLoadBalancerCacheFromCollection()`, which derives the mapping from all
stored normal decks using Core's `Deck::config_id()` behavior; filtered decks
are omitted, while normal-deck config IDs with no matching stored config are
preserved. Missing deck mappings are skipped by the history grouping. Unit 94
adds `loadBalancerContextForNow()`, which calls the existing
`timingTodayForNow()` path once and returns `daysElapsed`, its absolute
`nextDayAt` timestamp, and a cache built for that same day in one immutable
collection result. The caller-mapping API remains available. Actual review
answer call-site wiring, cache mutation after an answer, transaction
persistence/undo, Reviewer UI, and full cross-platform review integration
remain incomplete.

### Unit 95 — collection-backed load-balanced interval decision

`CollectionSqliteStorage.findLoadBalancedIntervalForNow()` resolves one
`CollectionLoadBalancerContext` for the optional injected `now` and forwards
its cache and `nextDayAt`, together with the caller-selected deck-config ID,
nullable note ID, current interval, bounds, and nullable fuzz seed, to the
existing pure `anki_backend_models.findLoadBalancedInterval()` helper. The
collection method returns the helper's nullable decision unchanged and does
not apply it or mutate card, cache, or database state. This closes composition
of the collection timing/cache context with the pure interval decision. The
caller still selects the relevant card and preset context and applies the
answer; scheduler answer-state transitions, cache mutation during answer,
transaction persistence/undo, scheduler execution, and Reviewer UI remain
open.

### Unit 96 — ReviewState load-balancer interval hook

`ReviewSchedulingContext` now accepts an optional resolver for the fixed
preset/note/seed load-balancer context. Passing ReviewState intervals call it
after interval multipliers and final minimum/maximum handling; a nullable
result falls back to the existing deterministic fuzz path. Early reviews skip
the resolver and retain their rounded/clamped calculation. The hook is carried
through FSRS next-state derivation and preserves the sequential Hard/Good/Easy
minimums. Collection construction of a reusable resolver, answer-time cache
mutation, card/revlog persistence, transactions/undo, application call-site
wiring, and Reviewer UI remain open.

### Unit 97 — reusable review interval resolver from collection context

`CollectionLoadBalancerContext.reviewIntervalResolver()` captures the
context's existing cache and `nextDayAt` and fixes the selected deck-config ID,
nullable note ID, and nullable fuzz seed. Each callback call forwards only its
interval and minimum/maximum bounds to the existing pure
`anki_backend_models.findLoadBalancedInterval()` helper and returns its
nullable decision unchanged. Creating or reusing the callback performs no
collection reads, timing calculation, cache copy, or mutation. This closes
reusable resolver construction from a collection snapshot. Host
answer/scheduler call-site wiring, answer-time cache mutation, persistence/undo,
and Reviewer UI remain open.

### Unit 98 — collection-backed review scheduling context assembly

`ReviewSchedulingContext.withLoadBalancedIntervalResolver()` copies every
existing scheduler input unchanged and attaches the collection resolver.
`CollectionSqliteStorage.reviewSchedulingContextWithLoadBalancerForNow()`
accepts the host-composed scheduling context and Core-resolved preset, nullable
note, nullable fuzz seed, and optional `now`; it resolves one collection timing
and load-balancer cache snapshot, then fixes those values in the resolver.
That callback reuses its snapshot for all answer intervals. Collection-backed
`ReviewSchedulingContext` assembly is closed. Card/preset/note/bury resolution,
the application `get_scheduling_states` call site, answer persistence,
answer-time cache updates, transactions/undo, and Reviewer UI remain open.

### Unit 99 — collection card and home-deck review context selection

`CollectionSqliteStorage.reviewSchedulingContextWithCardLoadBalancerForNow()`
accepts a card ID, base `ReviewSchedulingContext`, load-balancer enablement,
nullable answer fuzz seed, and optional clock. Disabled load balancing returns
the base context before any card, deck, config, timing, or cache lookup. When
enabled, it reads the card, selects `originalDeckId` when nonzero or `deckId`
otherwise, and uses that home deck's config ID. A filtered home deck has no
config ID and leaves the base context unchanged. For a normal deck, the note ID
is supplied only when the stored config has `buryReviews` enabled; a missing
config row retains its config ID and behaves as bury disabled. The method then
attaches Unit 98's resolver from one timing/cache snapshot with the caller's
fuzz seed and preserves all base scheduling inputs. Missing cards fail as a
not-found state error. This closes storage-backed card/home-deck/config/bury
selection only. The app `get_scheduling_states`/answer call site, per-answer
interval application, answer-time cache mutation, card/revlog persistence,
transactions/undo, and Reviewer UI remain open.

### Unit 100 — post-answer load-balancer cache addition

`CollectionLoadBalancerContext.addAnsweredReviewCard()` accepts the
successfully updated card and the already-resolved home deck config ID. It adds
the card's ID, note ID, and post-answer interval to the existing in-memory
`LoadBalancerCache` only when the resulting queue is Review and the config ID
is present. Unknown presets and intervals outside the cache retain Unit 91's
no-op behavior. This closes the post-success cache-add helper only; the app
answer call site, transaction ordering and persistence, error/rollback
coordination, removal semantics where separately needed, undo, and Reviewer UI
remain open.

### Unit 101 — collection composition of review answer states

`CollectionSqliteStorage.reviewCardSchedulingStatesWithCardLoadBalancerForNow()`
accepts a caller-resolved `ReviewCardState`, base `ReviewSchedulingContext`,
card ID, load-balancer enablement, nullable fuzz seed, and optional clock. The
review state and base scheduler settings must come from the same host snapshot.
When enabled, it composes Unit 99's card-specific context once; when disabled,
it calls `nextStates()` with the base context without collection reads. It
returns `ReviewCardState.nextStates()` unchanged and does not derive current
review state or FSRS inputs. `nextStates()` may calculate FSRS answer outcomes
from the supplied context. The method does not persist cards or revlogs or
mutate the cache. This closes read-only answer-state calculation composition
for a supplied review state only. Stored current-state retrieval, filtered-deck
preview/rescheduling, non-review card types, actual answer command application,
cache-update call-site wiring, persistence, transactions/undo, and Reviewer UI
remain open.

### Unit 103 — collection-backed current normal-deck review state

`CollectionSqliteStorage.currentReviewCardStateForNow()` reads the stored card
and its currently assigned deck, requires an ordinary Review card in a normal
deck, and resolves `timingTodayForNow()` once. It applies Core's normal-deck due
rule by clamping the stored due day to `min(card.due, daysElapsed)` and passes
that same `daysElapsed` into `ReviewCardState.fromCard()`. Missing cards,
missing decks, non-review cards, and filtered decks return clear state errors.
This provides current review-state retrieval for normal decks only. Filtered
preview/rescheduling state, new/learning/relearning states, FSRS memory-state
derivation, answer application, answer persistence and cache updates,
transaction/undo behavior, and Reviewer UI remain open.

### Unit 104 — stored normal-deck Review answer states

`CollectionSqliteStorage.reviewCardSchedulingStatesForCardForNow()` reads one
stored card, validates that it is an ordinary Review card in a normal deck,
and projects its current state using one collection timing snapshot. It then
calculates all four answer-button states from the caller's base
`ReviewSchedulingContext`. When load balancing is enabled, card/home-deck
selection and the resolver cache use that same card and timing snapshot; when
disabled, the method skips load-balancer config and history reads. The supplied
nullable fuzz seed and scheduler inputs remain caller-owned, and the method is
read-only: it does not derive FSRS memory state or apply or persist answers.
This closes whole stored normal-deck Review answer-state calculation only.
Filtered preview/rescheduling, new/learning/relearning states, FSRS derivation,
answer application, cache updates, persistence, transactions/undo, and Reviewer
UI remain open.

### Unit 105 — resolved deck config projection into review context

`ReviewSchedulingContext.withDeckConfig()` projects the already Core-normalized
resolved config's review multipliers, interval bounds, leech/lapse settings,
learning/relearning step minutes, and graduation intervals. It derives the
empty-relearning-steps flag from the normalized config's relearning steps and
preserves caller-owned fuzz, load-balancer resolver, FSRS inputs/outcomes, and
other non-config context fields. It does not select or read a deck config,
normalize stored protobuf values, derive FSRS inputs, or assemble non-review
states.

Units 103–104 close stored ordinary Review card retrieval and all four
read-only answer-state calculations for a stored normal-deck Review card.
Remaining scheduler gaps include collection-backed resolved config selection,
FSRS memory-state derivation for that path, new/learning/relearning card state
assembly, filtered-deck preview/rescheduling, answer application, cache updates,
card/revlog persistence, transactions/undo, application call-site wiring, and
Reviewer UI.

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
- Remaining scheduler work: resolved deck-config selection/projection into the
  collection-backed answer path, FSRS derivation, non-review/filtered-deck state
  assembly, answer-call-site wiring, persisted scheduling changes,
  transactions/undo, and orchestration. Stored normal-deck Review state
  retrieval and answer-state calculation are closed by Units 103–104.
  Collection-backed due-card history and
  the Unit94 timing-plus-cache context are available; Unit90 groups
  caller-preloaded history, and `CollectionSqliteStorage.deckTree()` provides
  queue-count aggregation. Unit89 adds the pure preloaded-context interval
  decision, and Unit96 adds the pure ReviewState interval hook, but these
  helpers do not complete collection call-site or full cross-platform review
  integration.
- Answer persistence, revlog mutation, undo, and collection transactions.
- Reviewer UI, navigation, timing, and platform IO.

These remain in the Core/backend or host adapter until their own shared Dart
units are implemented. This ledger describes the pure transition slice; it does
not claim scheduler execution or full review-session migration.
