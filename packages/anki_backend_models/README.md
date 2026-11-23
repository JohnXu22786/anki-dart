# anki_backend_models

Shared Dart models and pure calculations adapted from Anki Core. The package
does not access the collection database or run the scheduler.

`EasyDay` and `calculateEasyDaysModifiers()` port Core's easy-day load
normalization. `IntervalLoadCandidate` and `calculateIntervalLoadWeight()` port
the per-interval weight formula, including its float32 arithmetic and explicit
sibling and easy-day modifier inputs. Random weighted selection, sibling
search and modifier derivation, card-history reads, configuration lookup, and
scheduler integration remain outside this package.

Pinned Anki Core source digests and license attribution are recorded in
`SOURCE.sha256` and `NOTICE.md`.
