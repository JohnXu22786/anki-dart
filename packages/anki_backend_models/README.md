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
for one day. Card-history reads, day/date derivation, deck-to-config resolution,
random weighted selection, and scheduler integration remain outside this
package; these helpers do not implement full load balancing.

Pinned Anki Core source digests and license attribution are recorded in
`SOURCE.sha256` and `NOTICE.md`.
