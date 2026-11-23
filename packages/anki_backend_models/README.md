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
