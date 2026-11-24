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
- Remaining scheduler work: filtered-deck rescheduling and normal-state
  resolution, answer-call-site wiring, persisted scheduling changes,
  transactions/undo, and orchestration. Stored non-rescheduling filtered
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
  New, Learn, Review, and Relearn cards in rescheduling filtered decks. It does
  not close answer-state composition, Preview wrapping, or rescheduling
  execution.
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
