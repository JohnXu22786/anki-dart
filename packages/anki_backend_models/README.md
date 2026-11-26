# anki_backend_models

Shared Dart models and pure calculations adapted from Anki Core. The package
does not access the collection database or run the scheduler.

`EasyDay` and `calculateEasyDaysModifiers()` port Core's easy-day load
normalization. `buildEasyDaysPercentages()` projects stored deck-config IDs to
parsed seven-day values without resolving decks to configurations.
`IntervalLoadCandidate` and `calculateIntervalLoadWeight()` port
the per-interval weight formula, including its float32 arithmetic and explicit
sibling and easy-day modifier inputs. `calculateSiblingDayModifiers()` applies
Core's five-day neighborhood factors to explicit sibling day indices in an
inclusive interval window within Core's 99-day load-balancer cache.
`calculateSiblingModifiers()` searches all caller-supplied preset buckets for
the selected note, deduplicates sibling days, and applies those factors.
`LoadBalancerDay` tracks caller-supplied card/note pairs and note membership
for one day. `selectWeightedInterval()` provides Core's seeded weighted
selection over caller-ordered candidates, matching the pinned rand 0.9.4,
rand_chacha 0.9.0, and rand_core 0.9.3 behavior. `intervalToWeekday()` applies
Core's interval offset to an absolute Unix timestamp, then projects the result
to the machine's local Monday-based weekday. `findLoadBalancedInterval()`
composes those pure helpers over caller-supplied 99-day preset caches,
seven-day easy-day settings, timestamp, selected preset, and optional note and
seed. `LoadBalancerCache.fromHistory()` groups the already-read, ordered
99-day card history by a caller-supplied deck-to-config map and projects
easy-day settings for all stored configs, matching Core's constructor cache
assembly. `CollectionSqliteStorage.buildLoadBalancerCache()` reads the
caller-selected 99-day history range and stored configs, then delegates to this
pure model. The collection day and deck-to-config map remain caller inputs;
weekday/timezone derivation, persisted scheduling changes, scheduler wiring,
answer/reviewer UI, and full cross-platform review integration remain outside
this model package. `LoadBalancerCache.addCard()` and `removeCard()` update
only the in-memory day buckets, matching Core's cache bookkeeping.

Pinned Anki Core source digests and license attribution are recorded in
`SOURCE.sha256` and `NOTICE.md`.

`ReviewSchedulingContext.loadBalancedIntervalResolver` accepts a
`ReviewLoadBalancerIntervalResolver` for review intervals after Core's
multipliers and bounds are applied. A null decision falls back to ordinary
deterministic fuzz; early reviews bypass the resolver. The collection package
can construct this callback from an existing timing/cache snapshot, fixing the
preset, note, and answer seed while each interval supplies its own value and
bounds. `ReviewSchedulingContext.withLoadBalancedIntervalResolver()` returns a
copy that preserves all existing scheduling fields while attaching the
resolver. Collection-backed assembly is provided by
`CollectionSqliteStorage.reviewSchedulingContextWithLoadBalancerForNow()`;
scheduler call-site wiring, answer-time cache updates, persistence,
transactions, and Reviewer UI remain outside these shared packages.

`ReviewSchedulingContext.withDeckConfig()` projects review multipliers,
interval limits, leech/lapse settings, learning steps, and graduation intervals
from a caller-resolved `DeckConfig`. The config must already have Core-compatible
normalization/defaulting applied. Projection does not select or load a config,
derive fuzz or FSRS inputs, or replace caller-supplied dynamic scheduling
inputs. The source adaptation follows Core's `CardStateUpdater::state_context()`
and `learn_steps()` / `relearn_steps()`; collection-backed config selection,
FSRS derivation, non-review state assembly, answer application/persistence,
transactions/undo, and Reviewer UI remain outside this method.

`ReviewCardState.fromCard()` projects an already-loaded review card into its
current review state. The caller supplies Core's already-resolved effective due
value and collection `daysElapsed` from the same timing snapshot. The pure
projection preserves the stored interval, ease factor, lapses, and FSRS memory
state; it does not read collection data or resolve filtered-deck due values.

`cardAnswerFromSchedulingStates()` builds the generated `CardAnswer` protocol
request from an existing generated `SchedulingStates` snapshot and a selected
rating. The caller supplies the card's `customData` snapshot; the builder copies
it into the selected new state while leaving the current-state projection
unchanged. This is required because `GetQueuedCards` does not populate
`SchedulingState.custom_data`. It selects the matching outcome, preserves the
signed 64-bit answer timestamp and card ID, validates the unsigned 32-bit
elapsed time, and copies
the current and selected state messages so they do not alias the input. It
constructs a request only; applying the answer, updating revlogs or collection
state, and transaction/undo behavior remain caller-owned.

`applyLearningCardAnswerState()` accepts a generated `CardAnswer` whose card ID
matches the supplied Card, whose `currentState` is Normal/New or Normal/Learning,
and whose `newState` is Normal/Learning. It returns a copied Card with Learn
type, caller-resolved Learn or day-Learn queue and due value, the answer's step
count, optional FSRS memory state and custom data, one reps increment, and the
Core original-position behavior. Desired retention is caller supplied and
nullable. The helper does not resolve due classification, scheduler time,
rollover or fuzz, and does not derive revlogs, persist data, or update
collection state.

`applyReviewCardAnswerState()` accepts a generated `CardAnswer` with a matching
card ID, a supported Normal current state, and exactly Normal/Review new state.
It returns a copied Card using the caller-resolved due day and applies the
Review interval, rounded ease factor, lapses, optional memory state, custom
data when present (preserving existing custom data when the field is absent),
reps increment, and Core original-position behavior. Due-day resolution,
revlog derivation, collection writes, and transaction/undo behavior remain
caller-owned.

`revlogEntryFromCardAnswer()` derives the shared `RevlogEntry` model from a
supplied generated `CardAnswer`, caller-provided `usn`, and explicit seconds
until day rollover. It follows Core's interval-to-day rollover conversion,
uses the current state's review kind and the new state's ease factor, and
preserves the answer's 64-bit card ID and timestamp. It is pure and does not
read timing or collection data, apply the answer, persist a revlog, update
caches, or manage undo.

`LearningCardState.fromCard()` projects an already-loaded Learn card using the
current step delay and elapsed seconds supplied by the caller from the matching
Core scheduler snapshot. It preserves the card's remaining step count and FSRS
memory state. The pure projection does not calculate timing, fuzz, the current
delay, filtered-deck wrappers, or the current Review state.

`FilteredPreviewState` and `FilteredPreviewSchedulingStates` calculate the
current filtered-preview state and Again/Hard/Good/Easy outcomes from explicit
u32 second delays. Current state remains unfinished at zero seconds; zero-delay
answer outcomes and Easy are finished. Collection lookup, delay configuration,
filtered-deck search/limits, and rescheduling remain outside this pure model.
