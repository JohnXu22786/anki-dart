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
`ReviewSchedulingContext`. It resolves the assigned normal deck's config and
projects its scheduler fields while preserving caller-owned dynamic inputs. A
missing config row uses Core-compatible defaults; config ID zero is invalid.
When load balancing is enabled, the same resolved config supplies both the
preset and `buryReviews` behavior, and one timing snapshot feeds state and cache
resolution. When disabled, config is read but load-balancer cache/history is
not. The nullable fuzz seed and other dynamic inputs remain caller-owned, and
the method is read-only: it does not derive FSRS memory state or apply or
persist answers. This closes whole stored normal-deck Review answer-state
calculation with collection-backed resolved config selection. Filtered
preview/rescheduling, new/learning/relearning states, FSRS derivation, answer
application, cache updates, persistence, transactions/undo, and Reviewer UI
remain open.

### Unit 105 — resolved deck config projection into review context

`ReviewSchedulingContext.withDeckConfig()` projects the already Core-normalized
resolved config's review multipliers, interval bounds, leech/lapse settings,
learning/relearning step minutes, and graduation intervals. It derives the
empty-relearning-steps flag from the normalized config's relearning steps and
preserves caller-owned fuzz, load-balancer resolver, FSRS inputs/outcomes, and
other non-config context fields. It does not select or read a deck config,
normalize stored protobuf values, derive FSRS inputs, or assemble non-review
states.

Units 103–109 close stored ordinary Review card retrieval, all four read-only
answer-state calculations with collection-backed config selection, missing
FSRS memory-state derivation, and FSRS answer outcomes for stored normal-deck
Review cards. Unit 110 closes the two FSRS short-term settings for that same
path. Unit 111 closes stored normal-deck New answer-state calculation only.
Remaining scheduler gaps include Relearning state assembly,
filtered-deck preview/rescheduling, answer application, cache updates,
card/revlog persistence, transactions/undo, application call-site wiring, and
Reviewer UI.

### Unit 106 — collection config in stored Review answer states

`CollectionSqliteStorage.reviewCardSchedulingStatesForCardForNow()` resolves
the assigned normal deck's config before calculating answer-button states,
then applies `ReviewSchedulingContext.withDeckConfig()` while preserving
caller-owned fuzz, FSRS results and parameters, feature flags, and other
dynamic inputs. A missing config row follows Core-compatible default config
values; a normal deck with config ID zero returns an explicit invalid-config
error. Load balancing reuses the resolved config for preset and `buryReviews`
selection and shares one timing snapshot with current-state projection. The
disabled path reads scheduler config but does not load cache/history. Config
selection and projection are closed for this stored normal-deck Review answer
path; Unit 108 adds missing FSRS memory derivation, while FSRS answer outcomes
and non-review/filtered-deck state assembly remain open.

### Unit 108 — derive missing FSRS memory from review history

When collection FSRS is enabled and a stored normal-deck Review card has no
memory state, `reviewCardSchedulingStatesForCardForNow()` reads that card's
revlogs through `RevlogStorage`, orders them by revlog ID, and derives the
current memory state with `computeFsrsMemoryState()`. It uses the resolved deck
config's FSRS parameters, historical retention, and UTC-midnight ignore-before
cutoff, plus the existing timing snapshot's `nextDayAt`. Existing memory state
is reused, and a history with no qualifying reviews leaves the state null.
Disabled FSRS does not read revlog history. The caller's supplied FSRS
parameters and answer outputs remain unchanged; FSRS answer intervals and
complete answer-state parity are not part of this unit.

This closes collection-backed memory-state derivation for stored normal-deck
Review cards. FSRS answer outcomes derived from that state and
non-review/filtered state assembly remain open.

### Unit 109 — derive FSRS answer outcomes for stored Review cards

When collection FSRS is enabled, `reviewCardSchedulingStatesForCardForNow()`
uses the resolved deck config's FSRS parameters and the assigned deck's
effective desired retention to calculate all four Core-style FSRS outcomes.
It reuses the current or history-derived memory state and derives elapsed days
from the same timing snapshot's `nextDayAt` and the stored last-review time,
falling back to `RevlogStorage.timeOfLastReview()` and then zero when no time is
available. It attaches those values as precomputed outputs on a copied
`ReviewSchedulingContext`, preserving the caller's other scheduler inputs and
preventing due-based elapsed days from replacing the explicit FSRS interval.

This closes collection-backed FSRS answer interval and memory-state derivation
for stored normal-deck Review cards. FSRS feature-flag settings, short-term
option derivation, non-review/filtered-deck states, answer application and
persistence, cache mutation, transactions/undo, app call-site wiring, and
Reviewer UI remain open.

### Unit 110 — derive FSRS short-term settings for stored Review answers

The stored normal-deck Review answer-state path reads the global
`fsrs_short_term_with_steps_enabled` boolean and derives `fsrsAllowShortTerm`
from the global FSRS enablement and the already-resolved deck config: disabled
FSRS forces false, empty FSRS params use Core's default-params true fallback,
and parameter sets of at least 19 values enable the option only when entries 17
and 18 are both positive. It projects those two settings onto a copy of the
caller's `ReviewSchedulingContext`, preserving its FSRS outputs, parameters,
fuzz, and load-balancer resolver. Both values are read alongside the existing
FSRS setting and use the same resolved config as answer-state calculation.

This closes the two FSRS short-term settings for stored normal-deck Review
answer states. New/learning/relearning card state assembly,
filtered-deck preview/rescheduling, answer application and persistence, cache
mutation, transactions/undo, app call-site wiring, and Reviewer UI remain open.

### Unit 111 — stored normal-deck New answer states

`CollectionSqliteStorage.newCardSchedulingStatesForCard()` reads a stored New
card in its assigned normal deck, clamps its stored due position to zero, and
resolves the deck config with Core defaults when its row is missing. It
projects the normalized deck steps, graduation intervals, and multipliers onto
the caller's context, derives the two FSRS short-term flags from collection
config, and delegates all four buttons to `NewCardState.nextStates()`. Other
caller-owned dynamic context fields remain unchanged. This path does not read
revlogs, derive FSRS memory/outcomes, or load load-balancer history/cache. It is
read-only and reports missing card/deck, non-New card, filtered deck, and
missing config ID errors.

This closes stored normal-deck New answer-state calculation only. At this
point Learning and Relearning state retrieval/assembly, filtered-deck
preview/rescheduling, answer application and persistence, cache mutation,
transactions/undo, app call-site wiring, and Reviewer UI remain open.

### Unit 113 — stored normal-deck Learn answer states

`CollectionSqliteStorage.learningCardSchedulingStatesForCard()` requires the
caller to provide `scheduledSecs` and `elapsedSecs` resolved from one scheduler
snapshot. It does not derive them from the stored queue, due value, or
timestamps. `LearningCardState.fromCard()` projects the stored remaining steps
and memory state along with those exact timings. The method resolves the
assigned normal deck's learning/relearning config, applies Core defaults when
the config row is absent, and composes the two collection FSRS short-term flags
with the caller's existing `ReviewSchedulingContext`. It returns the four
answer-button states without reading revlogs or load-balancer cache/history or
persisting answers. Missing cards/decks/config IDs, non-Learn cards, and
filtered decks fail clearly.

This closes stored normal-deck Learn answer-state calculation only. Relearning
state assembly, filtered-deck preview/rescheduling, answer application and
persistence, cache mutation, transactions/undo, app call-site wiring, and
Reviewer UI remain open until Unit 114 below.

### Unit 114 — stored normal-deck Relearn answer states

`RelearningCardState.fromCard()` projects a stored Relearn card into Core's
paired current learning and review states. It uses caller-resolved
`scheduledSecs` and `elapsedSecs`, and preserves the stored remaining steps,
interval, ease, lapses, and FSRS memory. It rejects cards of other types.

`CollectionSqliteStorage.relearningCardSchedulingStatesForCard()` resolves the
stored card's normal deck config, uses Core defaults when the config row is
missing, and composes that config and the collection FSRS short-term flags with
the caller's scheduler context. It delegates Again/Hard/Good/Easy to the
existing pure Relearn transitions. It does not infer timing, read revlogs or
load-balancer history/cache, mutate stored state, or support filtered decks.
Missing cards/decks/config IDs, non-Relearn cards, and filtered decks fail
clearly. This closes stored normal-deck Relearn state assembly only; filtered
deck preview/rescheduling, answer application, cache mutation, transactions,
app call-site wiring, and Reviewer UI remain open.

### Unit 119 — current Learn state in rescheduling filtered decks

`CollectionSqliteStorage.currentReschedulingFilteredLearningCardState()` reads
a stored Learn card assigned to a filtered deck with rescheduling enabled. The
caller supplies `scheduledSecs` resolved from the current learning step and
`elapsedSecs` from the scheduler timing snapshot; this method does not infer
either value from queue, due, or timestamps. `LearningCardState.fromCard()`
preserves those timings, stored remaining steps, and memory state. The
read-only projection does not read deck config, revlogs, or load-balancer
cache/history. Missing cards/decks, non-Learn cards, normal decks, and
non-rescheduling filtered decks fail clearly. This closes only current
unwrapped Learn-state projection for rescheduling filtered cards;
step/timing resolution, answer-state composition, full filtered
`ReschedulingFilterState` wrapping, other card types, filtered rescheduling
execution, answer application/persistence, transactions/undo, app call-site
wiring, and Reviewer UI remain open.

### Unit 120 — current Relearn state in rescheduling filtered decks

`CollectionSqliteStorage.currentReschedulingFilteredRelearningCardState()`
reads a stored Relearn card assigned to a filtered deck with rescheduling
enabled. The caller supplies `scheduledSecs` resolved from the current
relearning step and `elapsedSecs` from the scheduler timing snapshot; the
method does not infer timing from queue, due, or timestamps.
`RelearningCardState.fromCard()` preserves the supplied timings, remaining
steps, and stored Review interval, ease, lapses, and memory in the paired
current Learning and Review states. This read-only projection does not read
deck config, revlogs, or load-balancer cache/history. It rejects missing
cards/decks, non-Relearn cards, normal decks, and non-rescheduling filtered
decks. This closes only current paired Relearn-state projection for
rescheduling filtered cards; step/timing resolution, answer-state composition,
full filtered `ReschedulingFilterState` wrapping, other card types, filtered
rescheduling execution, answer application/persistence, transactions/undo, app
call-site wiring, and Reviewer UI remain open.

### Unit 121 — current rescheduling-filter wrapper for all stored card types

`CollectionSqliteStorage.currentReschedulingFilteredCardSchedulingState()`
returns the generated `SchedulingState` filtered-rescheduling wrapper for
stored New, Learn, Review, and Relearn cards. It reuses the existing current
state projections, preserving New position resolution, Review effective-due
and timing behavior, and explicit caller-resolved Learn/Relearn timing. It
rejects missing cards/decks, unsupported card types, normal decks, and filtered
decks without rescheduling. The read-only API does not read answer
configuration, revlogs, FSRS history/cache, or mutate collection data. This
closes only current-state wrapper assembly for these four card types; answer
state composition, non-rescheduling Preview wrapping, filtered-card
query/gather, rescheduling execution, answer application/persistence,
transactions/undo, and app/UI integration remain open.

### Unit 118 — current New state in rescheduling filtered decks

`CollectionSqliteStorage.currentReschedulingFilteredNewCardState()` reads a
stored New card assigned to a filtered deck with rescheduling enabled. It
resolves position from nonzero `originalDue`, otherwise stored `due`, and
clamps negative positions to zero before creating `NewCardState`. This
read-only projection returns only the current New state and does not read deck
config, revlogs, or load-balancer cache/history, or calculate answer outcomes.
It rejects missing cards/decks, non-New cards, normal decks, and
non-rescheduling filtered decks. This closes only current unwrapped New-state
projection for rescheduling filtered cards; answer-state composition, full
filtered `ReschedulingFilterState` wrapping, other card types, filtered
rescheduling execution, answer application/persistence, transactions/undo,
app call-site wiring, and Reviewer UI remain open.

### Unit 125 — stored Review answer states in rescheduling filtered decks

`CollectionSqliteStorage.reschedulingFilteredReviewCardSchedulingStatesForCardForNow()`
returns current and Again/Hard/Good/Easy states for a stored Review card
assigned to a rescheduling filtered deck. It resolves current due from nonzero
`originalDue`, otherwise stored `due`, without normal-deck clamping. One
caller-selected timing snapshot drives current elapsed days, FSRS history and
next-state derivation, and optional load-balancer context. The original/home
normal deck supplies the normalized config, with Core defaults when its config
row is absent. Collection FSRS behavior derives missing memory state from
ordered revlogs and computes answer outcomes; the optional load-balancer
resolver uses the home config, bury setting and caller fuzz seed. Current and
answer outcomes use the filtered-rescheduling wrapper, and Again maps to
Relearn when the supplied context makes that transition reachable. Invalid or
missing cards/decks and invalid home deck/config identity fail clearly. This
read-only method does not apply or persist answers. This closes stored
Review-card answer-state composition for rescheduling filtered decks only;
filtered scheduling execution, answer application/persistence,
transactions/undo, app call-site wiring, Preview wrapping, and Reviewer UI
remain open.

### Unit 122 — stored New answer states in rescheduling filtered decks

`CollectionSqliteStorage.reschedulingFilteredNewCardSchedulingStatesForCard()`
returns current and Again/Hard/Good/Easy states for a stored New card assigned
to a filtered deck with rescheduling enabled. It resolves the current position
using nonzero `originalDue`, otherwise stored `due`, and clamps negative
positions to zero. The answer outcomes reuse `NewCardState.nextStates()` with
the original home deck's normalized config and collection FSRS short-term
flags, preserving caller-owned dynamic context and using Core defaults when
the home config row is absent. Every current/outcome Normal state is wrapped
in `SchedulingState.Filtered.ReschedulingFilter.original_state`. Missing or
invalid cards, missing filtered/home decks, normal or non-rescheduling
filtered decks, absent original deck IDs, and missing home config IDs fail
clearly. The read-only API does not read revlogs, FSRS memory history, or
load-balancer cache/history, and does not apply or persist answers.

This closes only stored New-card answer-state composition in rescheduling
filtered decks. Learn, Relearn, and Review outcomes, non-rescheduling Preview
wrapping, filtered-card query/gather, rescheduling execution, answer
application/persistence, transactions/undo, and app/UI integration remain
open.

### Unit 123 — stored Learn answer states in rescheduling filtered decks

`CollectionSqliteStorage.reschedulingFilteredLearningCardSchedulingStatesForCard()`
returns the current and Again/Hard/Good/Easy states for a stored Learn card
assigned to a filtered deck with rescheduling enabled. The caller supplies
`scheduledSecs` for the current learning step and `elapsedSecs` from the same
scheduler timing snapshot; neither is inferred from stored queue, due, or
timestamps. `LearningCardState.fromCard()` preserves the stored remaining
steps and FSRS memory. The answer transitions use the original home deck's
normalized config and collection FSRS short-term flags, preserve caller-owned
dynamic context, and use Core defaults when the config row is absent. Every
current/outcome Normal state is wrapped in
`SchedulingState.Filtered.ReschedulingFilter.original_state`. Missing or
invalid cards, missing assigned/home decks, normal or non-rescheduling
filtered decks, missing original deck IDs, non-normal home decks, and missing
home config IDs fail clearly. This read-only path does not read revlogs, FSRS
memory history, or load-balancer cache/history, and does not apply or persist
answers.

This closes only stored Learn-card answer-state composition in rescheduling
filtered decks. Relearn and Review outcomes, non-rescheduling Preview wrapping,
filtered-card query/gather, rescheduling execution, answer application and
persistence, transactions/undo, and app/UI integration remain open.

### Unit 115 — pure filtered-preview current and answer states

`FilteredPreviewState` and `FilteredPreviewSchedulingStates` model Core's
current filtered-preview state and its Again/Hard/Good/Easy outcomes using
explicit caller-supplied unsigned 32-bit delay seconds. The current state is
unfinished even at a zero-second delay; for answer outcomes, zero seconds
finishes the preview, and Easy always finishes. This closes the pure Preview
transition calculation.

### Unit 116 — collection-backed filtered-preview states

`CollectionSqliteStorage.filteredPreviewSchedulingStatesForCard()` confirms
the stored card and its assigned deck, requires a non-rescheduling filtered
deck, and passes its stored Again/Hard/Good delays to Unit115's pure model.
Core's current state uses the Again delay while remaining unfinished even when
that delay is zero. The method returns all four answer outcomes without
resolving scheduler timing or mutating collection state. Missing cards/decks,
normal decks, and filtered decks configured to reschedule fail clearly. This
closes stored non-rescheduling filtered-preview delay assembly only; filtered
deck search/gathering, rescheduling, normal-state resolution, answer
application, cache updates, persistence, transactions/undo, application
call-site wiring, and Reviewer UI remain open.

### Unit 126 — collection-backed filtered Preview protocol states

`CollectionSqliteStorage.filteredPreviewSchedulingStatesProtoForCard()` reuses
the Unit116 collection validation and Unit115 Preview state calculation, then
wraps current and Again/Hard/Good/Easy in generated
`SchedulingState.filtered.preview` protocol states. It preserves each
`scheduledSecs` and `finished` value, including an unfinished zero-delay
current state and the finished Easy outcome. The read-only wrapper does not
resolve timing, apply answers, mutate caches, or persist scheduling.

This closes only collection-backed filtered Preview protocol-state assembly.
Filtered search/gather, execution, answer application and persistence,
transactions/undo, and Reviewer UI remain open.

### Unit 127 — normal-deck stored-card protocol state assembly

`CollectionSqliteStorage.normalCardSchedulingStatesProtoForCard()` dispatches
stored normal-deck New, Learn, Review, and Relearn cards to their existing
collection-backed answer-state projections, then wraps current and
Again/Hard/Good/Easy states in generated `SchedulingState.normal` values. It
preserves each transition's inner New/Learning/Review/Relearning oneof and
scheduling fields. Learn and Relearn require caller-supplied `scheduledSecs`
and `elapsedSecs`; Review receives the caller's `now`, load-balancer setting,
fuzz seed, and context. The API rejects missing or invalid cards, missing
assigned decks, filtered decks, and timing inputs that do not match the card
type. This closes only generated normal-deck scheduling-state assembly for
stored New/Learn/Review/Relearn cards. Answer application and persistence,
transactions/undo, app call-site wiring, and Reviewer UI remain open.

### Unit 128 — collection card scheduling-state dispatch

`CollectionSqliteStorage.schedulingStatesProtoForCard()` reads a stored card
and selects the existing generated state projection from its assigned deck
mode and card type. Normal decks reuse Unit127's New/Learn/Review/Relearn
assembly; rescheduling filtered decks reuse their matching filtered
New/Learn/Review/Relearn projections; non-rescheduling filtered decks reuse
Unit126's Preview assembly. Current and Again/Hard/Good/Easy remain generated
states in the selected mode's protocol oneofs. Review receives the caller's
timing snapshot, load-balancer setting, fuzz seed, and context, while Learn and
Relearn receive caller-resolved `scheduledSecs` and `elapsedSecs` unchanged.
The API preserves delegated card, deck, configuration, card-type, and required
timing errors. It is read-only and does not apply answers, persist card or
revlog state, or mutate caches. This closes only the unified collection
state-dispatch API; answer application and persistence, transactions/undo,
and application/UI call-site integration remain open.

### Unit 129 — CardAnswer request construction

`anki_backend_models.cardAnswerFromSchedulingStates()` builds the generated
`CardAnswer` request from a card ID, generated `SchedulingStates`, selected
rating, caller-supplied signed 64-bit answer timestamp, and elapsed-answer
milliseconds. It pairs the supplied current state with the outcome selected by
Again/Hard/Good/Easy, preserves normal, filtered Preview, and
filtered-rescheduling protocol wrappers, rejects missing required states and
elapsed values outside `uint32`, and copies the mutable current/outcome state
messages. It does not apply the answer, persist card or revlog changes, update
caches, or introduce answer-call-site wiring. This closes generated request
construction only; answer application, persistence, transactions/undo, and
application/UI call-site integration remain open.

### Unit 130 — collection stored-card CardAnswer request routing

`CollectionSqliteStorage.cardAnswerRequestForCard()` composes
`schedulingStatesProtoForCard()` with
`anki_backend_models.cardAnswerFromSchedulingStates()`. It routes the selected
rating to the corresponding outcome while preserving the generated state
wrapper selected for normal decks, rescheduling filtered decks, or filtered
Preview. The caller's card ID, signed answer timestamp, elapsed milliseconds,
review context and timing, load-balancer and fuzz inputs, and explicit
Learn/Relearn `scheduledSecs` and `elapsedSecs` remain the inputs to the
delegated builders; no timing is inferred from stored rows. Delegated stored
card, deck, card-type, timing, rating, and unsigned elapsed-time validation is
preserved. The API only constructs a request and remains read-only. This closes
only collection-level stored-card CardAnswer request routing/construction;
answer application and persistence, transactions/undo, and Reviewer UI remain
open.

### Unit 131 — persist a supplied post-answer card and revlog

`CollectionSqliteStorage.recordCardAnswerResult()` accepts the caller-computed
post-answer `Card` and `RevlogEntry`, requires them to identify the same
existing card, and updates the card while inserting the revlog in one SQLite
transaction. The operation uses the collection undo journal under the stable
`answerCard` identity, so undo restores the prior card and removes the new
revlog, and redo reapplies both. A revlog ID collision or card update failure
rolls back the whole write. This closes only persistence and undo/redo for
caller-supplied answer results. Scheduler calculation, CardAnswer request
routing, revlog field derivation, load-balancer cache mutation, and
Reviewer/app call-site orchestration remain caller-owned or open.

### Unit 132 — update the review cache after answer persistence

`CollectionSqliteStorage.recordCardAnswerResult()` optionally accepts a
caller-owned `CollectionLoadBalancerContext` and the already-resolved home
deck-config ID. After the atomic card/revlog operation commits, it delegates to
`CollectionLoadBalancerContext.addAnsweredReviewCard()` to add a resulting
Review-queue card to that in-memory cache. Non-review results and missing home
config IDs remain no-ops; failed writes and revlog collisions leave the cache
unchanged. This closes only persistence-to-load-balancer-cache mutation for
caller-supplied answer results. Scheduler answer derivation, home-config
resolution, app call-site orchestration, cache rebuild/undo invalidation, and
Reviewer UI remain open.

### Unit 133 — derive a RevlogEntry from CardAnswer

`anki_backend_models.revlogEntryFromCardAnswer()` converts a supplied
generated `CardAnswer` into the shared `RevlogEntry` model using caller-supplied
`usn` and seconds until day rollover. It derives current and next intervals,
ease factor, and review kind from normal New/Learning/Review/Relearning states,
filtered Preview states, and filtered rescheduling wrappers; maps ratings to
Core's one-based button values; and preserves the answer's exact 64-bit card ID
and timestamp plus elapsed milliseconds. Missing or unsupported state
wrappers and invalid numeric inputs are rejected. The helper does not read the
clock or collection, apply or persist the answer, mutate caches, or write undo
state. This closes only pure revlog derivation from a supplied CardAnswer;
answer application, call-site orchestration, and Reviewer UI remain open.

### Unit 134 — preserve Card custom data in CardAnswer requests

`cardAnswerFromSchedulingStates()` and
`CollectionSqliteStorage.cardAnswerRequestForCard()` accept the caller's
`Card.customData` snapshot and copy it into the selected generated
`CardAnswer.newState.customData`, including an empty string. The current state
remains the unchanged scheduling-state projection because `GetQueuedCards`
does not populate `SchedulingState.custom_data`; the request caller must provide
the Card value to prevent existing custom data from being cleared on answer.
Normal, rescheduling-filtered, and filtered-Preview request construction all
preserve this value without mutating the input states. This closes only Card
custom-data propagation into generated CardAnswer requests; applying the answer,
persisting Card or revlog rows, and Reviewer UI behavior remain separate work.

### Unit 135 — apply a Normal/New CardAnswer state to a Card snapshot

`anki_backend_models.applyNewCardAnswerState()` accepts a generated
`CardAnswer` only when its card ID matches and its `newState` wrapper is exactly
Normal/New. It returns a copied Card with New type/queue, the answer's due
position and custom data, one Core reps increment, and cleared original
position and FSRS memory state. Desired retention is an explicit nullable caller input and is applied
verbatim, including clearing an existing value when null. All other Card fields stay
unchanged, and neither input is mutated. This closes only pure application of a
Normal/New answer to a Card snapshot. Other scheduling states and wrappers,
collection/app wiring, revlog and persistence integration, transaction/undo, and
Reviewer UI remain open.

### Unit 136 — apply a Normal/Learning CardAnswer state to a Card snapshot

`anki_backend_models.applyLearningCardAnswerState()` accepts a generated
`CardAnswer` with a matching card ID, Normal/New or Normal/Learning current
state, and exactly Normal/Learning new state. It returns a copied Card with
Learn type, a caller-resolved intraday Learning or day-Learning queue and due
value, the new remaining-step count and optional memory state, copied custom
data, one reps increment, and Core's original-position behavior. Nullable
desired retention is caller supplied. This closes only pure Normal/Learning
Card snapshot application. Other answer states and wrappers, due calculation,
timing/rollover/fuzz and call-site resolution, revlog and persistence
integration, transactions/undo, app wiring, and Reviewer UI remain open.

### Unit 137 — apply a Normal/Review CardAnswer state to a Card snapshot

`anki_backend_models.applyReviewCardAnswerState()` accepts a generated
`CardAnswer` with a matching card ID, a supported Normal current state (New,
Learning, Review, or Relearning), and exactly Normal/Review new state with its
required scheduled-day, ease-factor, and lapse fields present. It returns a
copied Card with Review type/queue, caller-resolved due day, scheduled interval,
Core-rounded ease factor, answer lapses and optional memory state, zero
remaining steps, copied custom data, one reps increment, and Core's
original-position behavior. Custom data is replaced only when the protocol field
is present; an absent field preserves the Card's existing value. Nullable
desired retention is caller supplied.
This closes only pure Normal/Review Card snapshot application; Relearn and
filtered wrappers, due-day/timing resolution, revlog and persistence
integration, transactions/undo, app wiring, and Reviewer UI remain open.

### Unit 138 — apply a Normal/Relearning CardAnswer state to a Card snapshot

`anki_backend_models.applyRelearningCardAnswerState()` accepts a generated
`CardAnswer` with a matching card ID, a supported Normal current state (New,
Learning, Review, or Relearning), and exactly Normal/Relearning new state with
its paired Review and Learning values present. It maps interval, ease factor,
and lapses from the Review state, and remaining steps and optional FSRS memory
state from the Learning state. The copied Card uses Relearn type, a
caller-resolved Learning or day-Learning queue and due value, one reps
increment, and Core's original-position behavior. Custom data is replaced only
when its protocol field is present. Nullable desired retention remains a
caller-supplied input.
This closes only pure Normal/Relearning Card snapshot application; filtered
Relearning wrappers, due/timing resolution, revlog and persistence integration,
transactions/undo, app wiring, and Reviewer UI remain open.

### Unit 139 — apply and persist Normal CardAnswer results in the collection

`CollectionSqliteStorage.applyAndRecordCardAnswerResult()` accepts a
caller-held Card snapshot and generated CardAnswer, dispatches Normal/New,
Normal/Learning, Normal/Review, and Normal/Relearning to the corresponding
`anki_backend_models` snapshot helper, derives the matching RevlogEntry from
explicit caller-supplied USN and day-rollover seconds, and persists both values
through the existing atomic `recordCardAnswerResult()` operation. Learning and
Relearning due queue/value and Review due day remain explicit caller-resolved
inputs, as does nullable desired retention; no timing or collection state is
read to resolve them. The operation returns the applied Card after commit and
preserves the existing post-commit review-cache update and undo/redo behavior.
Missing, mismatched, malformed, or filtered answers and missing due resolution
are rejected before writes. This closes only collection orchestration for
caller-resolved Normal answers through existing apply/derive/persist/cache
helpers. Due resolution, filtered wrappers, app/Reviewer call-site integration,
additional transaction/undo work, and UI remain open.

### Unit 140 — apply filtered Preview CardAnswer states to a Card snapshot

`anki_backend_models.applyFilteredPreviewCardAnswerState()` accepts a generated
`CardAnswer` whose current and new states are exactly filtered Preview states,
with matching Card ID and required `scheduledSecs`/`finished` fields, and a Card
with a nonzero original deck ID. Unfinished previews require caller-resolved due
seconds and set PreviewRepeat queue. Finished previews restore the original deck
and nonzero original due, clear the restored metadata, and derive New/Review or
Learning/day-Learning queue from card type and restored due; negative queues are
preserved. Reps, ctype, desired retention and other unrelated Card values stay
unchanged. Custom data is copied only when present in the new state, including
an explicit empty value. The pure helper returns a new Card snapshot without
reading time or collection state, deriving a revlog, or persisting. Core
provenance for `rslib/src/scheduler/answering/learning.rs`,
`rslib/src/card/mod.rs`, and `proto/anki/scheduler.proto` is recorded in the
model package `NOTICE.md` and `SOURCE.sha256`. This closes only filtered Preview
Card snapshot application. Unit 141 adds the collection-level apply/record
orchestration described below; filtered rescheduling wrappers, normal-state
re-entry into rescheduling filtered decks, caller-side due calculation, and
app/UI integration remain open.

### Unit 141 — apply and persist filtered Preview CardAnswer results

`CollectionSqliteStorage.applyAndRecordFilteredPreviewCardAnswerResult()`
applies a generated filtered Preview `CardAnswer` to a caller-held Card
snapshot, derives its `RevlogEntry`, and atomically persists both through the
existing answer-result operation. The caller supplies the USN, day-rollover
seconds, and the due timestamp for unfinished Preview answers. The operation
returns the updated Card only after commit and preserves the existing undo,
redo, and post-commit review-cache behavior. It does not resolve timing, read a
stored Card, or access deck configuration or collection state to construct the
snapshot or due timestamp. This closes only collection-level filtered Preview
apply/record orchestration; caller-side timing resolution, collection-level
filtered rescheduling execution and persistence, app/Reviewer call-site
integration, remaining transaction/undo work, and UI integration remain open.

### Unit 142 — apply rescheduling-filtered CardAnswer states to a Card snapshot

`anki_backend_models.applyReschedulingFilteredCardAnswerState()` applies a
generated `CardAnswer` whose current state is a filtered/rescheduling wrapper
with a supported Normal original state. It accepts either a populated
top-level Normal new state, which restores the original deck and clears
filtered metadata before scheduling, or a filtered/rescheduling new state,
which keeps the card in the filtered deck and updates `originalDue` to the
resulting due. Existing Normal/New, Learning, Review, and Relearning snapshot
helpers apply the scheduling values, with due values/queues and nullable
desired retention supplied by the caller. Optional custom data is preserved
when absent and copied when present, including an explicit empty value. This
closes only pure Card snapshot application for generated rescheduling-filtered
answers; collection apply/record wiring, due/timing resolution, other filtered
execution, app/Reviewer integration, and UI remain open.

### Unit 143 — apply and persist rescheduling-filtered CardAnswer results

`CollectionSqliteStorage.applyAndRecordReschedulingFilteredCardAnswerResult()`
applies a generated rescheduling-filtered `CardAnswer` to a caller-held Card
snapshot with `applyReschedulingFilteredCardAnswerState()`, derives its
`RevlogEntry` from explicit caller-supplied USN and day-rollover seconds, and
persists both through the existing atomic `recordCardAnswerResult()` operation.
The caller supplies nullable desired retention and resolved Learning,
Relearning, or Review due inputs as required by the new Normal inner state. A
top-level Normal result leaves the filtered deck; a filtered/rescheduling
result remains filtered. The method returns the updated Card only after commit
and inherits the existing undo, redo, and post-commit cache behavior. It does
not query a stored Card or resolve timing, due, interval, fuzz, or deck
configuration. This closes only collection-level apply/record orchestration
for caller-resolved rescheduling-filtered answers; due/timing resolution,
additional rescheduling behavior, app/Reviewer wiring, additional
transaction/undo scope, and UI remain open.

### Unit 144 — orchestrate one stored-card answer through commit

`CollectionSqliteStorage.answerCard()` reads one stored Card snapshot, builds a
generated `CardAnswer` from the stored-card scheduling-state dispatch and the
requested rating, then routes strictly by the generated Normal, filtered
Preview, or filtered/rescheduling wrappers to the matching apply-and-record
operation. The stored Card's custom data is copied into the answer. The caller
supplies review context, scheduling timing and fuzz inputs, answer timestamp
and duration, USN, day-rollover seconds, desired retention, applicable
Learning/Relearning queue and due or Review due day, unfinished Preview due
timestamp, and optional load-balancer cache context/home config ID. The
operation reuses existing validation, Card/Revlog transaction, undo/redo, and
post-commit cache behavior, and returns only after commit. It does not resolve
due/timing inputs, add bulk answering, or wire application/UI call sites. This
closes only single-card request/apply/record orchestration; due/timing
resolution and app/Reviewer/UI integration remain open.

### Unit 145 — persist the answer timestamp on answered Cards

The composed `CollectionSqliteStorage.answerCard()` path now copies the
generated answer's `answeredAtMillis` to `Card.lastReviewTimeSecs` in whole
Unix seconds for Normal and filtered-rescheduling answers. Filtered Preview
answers retain the stored timestamp. The original stored Card snapshot remains
the transaction's expected-value guard, and the timestamp update is persisted
with the Card and Revlog in the existing undoable operation. This closes only
the composed answer timestamp mutation; answer-duration caps, other
post-answer behavior, due/timing resolution, and app/Reviewer/UI integration
remain open.

### Unit 146 — cap answer duration using caller-resolved deck config

The composed `CollectionSqliteStorage.answerCard()` operation accepts the
caller-resolved answer-duration cap in seconds from the card's home/original
deck config and caps its generated `CardAnswer` before deriving or persisting
the updated Card and Revlog. The capped milliseconds are recorded in the Revlog
for Normal, filtered Preview, and rescheduling answers. The operation validates
the cap's Core uint32 domain and does not read deck config. Correct config
resolution at Normal and filtered callers, other post-answer Core behavior,
due/timing resolution, and app/Reviewer/UI integration remain open.

### Unit 147 — apply caller-resolved leech suspension after a stored-card answer

The composed `CollectionSqliteStorage.answerCard()` operation accepts the
caller-resolved leech action for the card's home/original deck config. When the
generated Normal or filtered-rescheduling answer's resulting Review state is
leeched and the caller selects Suspend, the updated Card queue is set to
Suspended before its atomic Card and Revlog commit. A false flag preserves the
queue from state application, and filtered Preview answers are not treated as
leech transitions. The operation continues to use the generated state as its
leeched signal, validate and apply state before writing, and preserve existing
undo/redo and post-commit load-balancer behavior. This closes only
caller-resolved leech suspension in the composed single-card operation;
deck stats, sibling bury, queue updates, config resolution, due/timing
resolution, and app/Reviewer UI integration remain open.

### Unit 148 — add the Core leech tag during a stored-card answer

The composed `CollectionSqliteStorage.answerCard()` operation now adds Core's
`leech` tag to the answered Card's Note whenever the generated answer's new
state signals a leech, regardless of the caller-resolved suspension action.
Filtered Preview answers and non-leeched results do not add the tag. When a new
tag is needed, existing tags are deduplicated case-insensitively and sorted
case-insensitively, and the stored registry spelling is reused when present.
An already-present `leech` tag leaves the Note unchanged. A missing registry
row is registered with the answer USN, while an existing row is preserved. A
Note whose tags change receives Core's current modification time and the
answer USN. Note and tag-registry writes share the existing atomic undoable
Card+Revlog operation, so undo and redo include all affected rows. This closes
only answer-triggered leech-tag creation and its persistence/undo on the
composed single-card operation; deck stats, sibling bury, queue updates, config
resolution, due/timing resolution, and app/Reviewer UI integration remain
open.

### Unit 149 — update deck statistics during a stored-card answer

The composed `CollectionSqliteStorage.answerCard()` operation now updates
Core-compatible daily deck statistics in the same undoable transaction as the
Card, Revlog, and any leech Note/tag changes. It uses the stored Card's
assigned deck and pre-answer queue, the caller-resolved collection day, and the
generated answer's capped milliseconds. The assigned deck and each existing
parent deck receive the queue-specific studied count and wrapped int32
millisecond delta; a day change resets the stored daily counters first. Deck
modification time and USN follow the answer operation. A stale Card check
finishes before any deck statistic write, and undo/redo includes affected deck
rows. This closes only answer-triggered deck statistics on the composed
single-card operation; sibling bury, queue updates, config resolution,
due/timing resolution, and app/Reviewer UI integration remain open.

### Unit 150 — bury eligible siblings after a stored-card answer

The composed `CollectionSqliteStorage.answerCard()` operation accepts the
caller-resolved new-card, interday-learning, and review sibling-bury flags from
the answered card's home/original deck config. It uses the transaction's
expected pre-answer Card and Note ID, applies Core's gather-order exclusions
based on the original queue, and selects only same-note New, Review, and
DayLearn siblings other than the answered card. Eligible siblings that are
not suspended are stored as `SchedBuried` with the answer USN and Core-compatible
current modification seconds; all other Card fields are preserved. These
changes commit in the existing undoable answer operation with the answered
Card, Revlog, leech Note/tag, and deck statistics, so undo and redo cover all
affected rows. This closes only answer-triggered sibling bury on the composed
single-card operation; queue updates, caller-side config resolution,
due/timing/fuzz resolution, app/Reviewer call-site integration, and UI remain
open.

### Unit 151 — resolve home-deck answer settings from a stored Card

`CollectionSqliteStorage.answerDeckConfigForCard()` reads a stored Card,
validates its assigned deck, and resolves the home deck from nonzero
`Card.originalDeckId` or otherwise the assigned deck. It validates the home
deck's config ID and returns the config ID, answer-duration cap, leech
suspension action, and new/interday-learning/review sibling-bury flags from
that home DeckConfig. A missing config row uses `DeckConfig.defaults()` while
preserving the home config ID. The resolver is read-only and does not resolve
scheduling timing, due values, fuzz, or caller-owned answer inputs. This closes
only stored-card home-config resolution for Unit146/147/150 `answerCard()`
inputs; answer-state config, due/timing/fuzz resolution, scheduling-context
construction, app/Reviewer call-site integration, and UI remain open.

### Unit 117 — current Review state in rescheduling filtered decks

`CollectionSqliteStorage.currentReschedulingFilteredReviewCardStateForNow()`
reads a stored Review card and requires its assigned deck to be a filtered deck
with rescheduling enabled. It resolves effective due to nonzero
`originalDue`, otherwise stored `due`, without normal-deck clamping, and
projects the current state with `ReviewCardState.fromCard()` using one
caller-supplied `timingTodayForNow()` snapshot. This read-only path does not
read deck config, revlogs, FSRS history, or load-balancer cache/history. It
rejects missing cards/decks, non-Review cards, normal decks, and filtered decks
that do not reschedule. This closes only current unwrapped Review-state
projection for rescheduling filtered cards; answer-state composition, full
filtered `ReschedulingFilterState` wrapping, other card types, filtered
rescheduling execution, answer application/persistence, transactions/undo,
app call-site wiring, and Reviewer UI remain open.

- New-card, learning-card, and existing relearning-card pure Again/Hard/Good/Easy
  transitions are now exposed by `NewCardState`, `LearningCardState`, and
  `RelearningCardState` in `anki_backend_models`. Learning-step minutes,
  graduation intervals, deterministic fuzz, and FSRS next states are supplied
  explicitly. Source hashes and AGPL attribution are in the package notice and
  `SOURCE.sha256`.
- FSRS parameter training.
- FSRS memory-state derivation has a pure per-card model in
  `anki_backend_models.computeFsrsMemoryState()`. It takes ordered revlogs,
  parameters, historical retention, cutoff, and the next-day timestamp as
  explicit inputs. Parameter training, collection queries, bulk writes,
  transactions, and rescheduling remain host-owned.
- Remaining scheduler work: caller-side due/timing/fuzz resolution,
  app/Reviewer call-site integration, additional transaction/undo work, and UI.
  Unit139 closes collection orchestration for caller-resolved Normal answers
  through existing apply, revlog derivation, persistence, and cache helpers.
  Unit144 closes one stored-card request/apply/record operation across Normal,
  filtered Preview, and filtered/rescheduling states using caller-resolved
  scheduling inputs. Stored non-rescheduling filtered
  Preview-delay assembly is closed by Unit116. Stored normal-deck Review state retrieval and
  collection-backed FSRS Review answer-state calculation are closed by Units
  103–110; stored normal-deck New answer-state calculation is closed by Unit
  111; Units 113–114 close stored normal-deck Learn and Relearn answer-state
  calculation. Unit117 closes current unwrapped Review-state projection for
  rescheduling filtered cards only. Unit118 closes only the current unwrapped
  New-state projection for rescheduling filtered cards. Unit122 closes only
  stored New answer-state composition for rescheduling filtered cards.
  Unit119 closes only the current unwrapped Learn-state projection for
  rescheduling filtered cards. Unit123 closes only stored Learn answer-state
  composition for rescheduling filtered cards.
  Unit124 closes only stored Relearn answer-state composition for rescheduling
  filtered cards. Unit125 closes only stored Review answer-state composition
  for rescheduling filtered cards; Preview wrapping remains open.
  Unit121 closes current-state `ReschedulingFilterState` wrapping for stored
  New, Learn, Review, and Relearn cards in rescheduling filtered decks. Unit127
  closes normal-deck generated protocol-state assembly for stored New, Learn,
  Review, and Relearn cards; Unit129 closes pure generated CardAnswer request
  construction, Unit130 closes its collection-level stored-card routing, Unit133
  closes pure revlog derivation, Unit134 closes Card custom-data propagation, and
  Unit135 closes pure Normal/New Card snapshot application, Unit136 closes
  pure Normal/Learning Card snapshot application, Unit137 closes pure
  Normal/Review Card snapshot application, and Unit138 closes pure
  Normal/Relearning Card snapshot application. Unit142 closes pure Card
  snapshot application for generated rescheduling-filtered answers. Unit139 closes collection
  orchestration for caller-resolved Normal answers through existing apply,
  revlog derivation, persistence, and cache helpers. Unit144 does not close due
  calculation or caller resolution, app/Reviewer call-site integration,
  additional transaction/undo work, or UI.
  Unit121 does
  not close answer-state composition, Preview wrapping, or rescheduling
  execution.
  Collection-backed due-card history and
  the Unit94 timing-plus-cache context are available; Unit90 groups
  caller-preloaded history, and `CollectionSqliteStorage.deckTree()` provides
  queue-count aggregation. Unit89 adds the pure preloaded-context interval
  decision, and Unit96 adds the pure ReviewState interval hook, but these
  helpers do not complete collection call-site or full cross-platform review
  integration.
- Bulk scheduler answering, caller-side due/timing/fuzz resolution, and
  app/Reviewer call-site integration.
- Other collection transaction and undo work beyond the atomic answer-result
  operation above.
- Reviewer UI, navigation, timing, and platform IO.

These remain in the Core/backend or host adapter until their own shared Dart
units are implemented. This ledger describes the pure transition slice; it does
not claim scheduler execution or full review-session migration.
