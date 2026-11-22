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
- Queue building, daily counts, load balancing, and collection-backed scheduler
  configuration reads.
- Answer persistence, revlog mutation, undo, and collection transactions.
- Reviewer UI, navigation, timing, and platform IO.

These remain in the Core/backend or host adapter until their own shared Dart
units are implemented. This ledger describes the pure transition slice; it does
not claim scheduler execution or full review-session migration.
