# Anki collection SQLite adapter

`anki_collection_sqlite` adapts a caller-selected SQLite driver and collection
location to `CollectionOpenDatabase`. It opens through the provided driver,
applies Anki Core's connection pragmas, forwards schema queries and SQL batches
to SQLite, and closes the connection without deleting the collection. It also
provides pinned stored card and note reads, card and note row mutations, and
source-compatible first-create callbacks using shared models from
`anki_backend_models`.

## Portable package I/O boundary

`CollectionSqliteStorage.createSnapshot()` flushes pending driver writes, rejects
an active SQL transaction, and asks the selected driver for a SQLite backup as
bytes. The native driver uses SQLite's public online backup API and an
ephemeral temporary database; it leaves the live connection open. Hosts inject
`CollectionMediaStorage` for their own media location; native hosts may use the
provided flat-directory adapter. `readMedia()` validates
the Anki filename before dispatch and returns a byte stream, while
`listMedia()` returns the available filenames. Missing media is represented
by `null`; streaming avoids loading an entire media object into memory.

| Target | SQLite snapshot | Media | Evidence / constraint |
| --- | --- | --- | --- |
| Android | Supported by native driver | Native flat-directory adapter or host injected | Native sqlite3 online backup; host selects media directory |
| iOS | Supported by native driver | Native flat-directory adapter or host injected | Native sqlite3 online backup; host selects media directory |
| Windows | Supported by native driver | Native flat-directory adapter or host injected | Native sqlite3 online backup; host selects media directory |
| macOS | Supported by native driver | Native flat-directory adapter or host injected | Native sqlite3 online backup; host selects media directory |
| Linux | Supported by native driver | Native flat-directory adapter or host injected | Native sqlite3 online backup; host selects media directory |
| Web | Supported by `VACUUM INTO` and a temporary `InMemoryFileSystem` VFS | IndexedDB media adapter | Verified in Chromium with persisted collection reopen, independent snapshot reopen, and media reopen/read/list |

Web snapshots use SQLite's public `VACUUM INTO` SQL command with a registered
public in-memory VFS, then copy and remove the temporary file bytes. The source
database is opened with URI support so SQLite can select that destination VFS;
the collection's IndexedDB VFS remains its own selected VFS. The host supplies
a stable, collection-specific media database by opening
`IndexedDbCollectionMediaStorage.openForCollection()` from
`anki_collection_sqlite_web_media.dart` and passing it as `mediaStorage` to
`experimentalWebCollectionSqliteDriver()`. Media Blobs are stored in a separate
IndexedDB database and streamed back in 64 KiB chunks. The Web SQLite VFS
remains experimental and does not guarantee crash durability for the collection
database.

`CollectionSqliteInitializationCallbacks` supplies initial collection
metadata, the localized default deck/config, and six stock note types.
`CollectionSqliteMigrationCallbacks` implements the catalogued schema 11 to
18 and 18 to 11 row/JSON/protobuf transformations on the same storage
connection. The host provides a typed `CollectionInitialTextProvider`,
source-compatible local timezone calculation, random 64-bit identifiers, and
a clock. Pass both callback objects to `openOrCreateCollection`; creation,
migrations, and defaults then share its exclusive transaction.

`CollectionSqliteSearchExecutor` implements the platform-neutral search-plan
host on an existing `CommonDatabase` connection. It executes Core's unbound
multi-statement sort preparations on that connection, then reads signed 64-bit
IDs from the ordered search query. The adapter preserves row order and binds
search arguments as supplied. Core's deterministic `field_at_index` and
`process_text` SQLite functions are registered on each connection; the other
search-specific functions and collations remain separate migration units.

`newCardCandidates()` queries queue-zero cards from one caller-selected deck,
and `activeNewCardCandidates()` queries those cards from an explicitly
supplied active-deck set. Both use Core's lowest-position, highest-position,
random-note, or random-card gather ordering; random modes require the caller's
u32 salt. The six-field candidate projection preserves exact signed 64-bit
values and SQLite row order. Active-deck derivation, limits, later sorting, and
scheduler execution remain caller-owned.

`dueCardCandidates()` reads review or interday-learning candidates from
caller-supplied active deck IDs, queue kind, Core review order, FSRS state, and
explicit scheduler timing values. It applies Core's inclusive due-day cutoff,
all review ordering modes, caller deck order for Deck sorts, and the deterministic
`fnvhash(id, mod)` tie-breaker. Candidate IDs and mtime remain exact signed
64-bit values; due uses Core's i32/default-zero conversion and reps is validated
as u32. It does not inspect collection configuration or choose active decks.

`getAllCardsDueInRange()` supplies load-balancer card history for a caller's
half-open day range. It returns a bucket for each day, includes all queue and
deck states, and preserves SQLite's natural row order within each bucket. Card,
note, and deck IDs remain signed 64-bit values, and stored due days are checked
as signed 32-bit values. Bounds follow Core's u32 contract and spans are capped
at the 99-day load-balancer window to keep allocation bounded. The
`buildLoadBalancerCache()` adapter combines that history with stored deck
configs and a caller-supplied deck-to-config map, then returns the shared
99-day preset cache. The caller derives `today`, and can choose the
`buildLoadBalancerCacheFromCollection()` convenience method to have the adapter
derive the mapping from stored normal decks using Core's `Deck::config_id()`
behavior, omitting filtered decks and retaining normal-deck config IDs even
when no config row exists. Its optional `additionalConfigs` input fills only
missing config rows, allowing selected Core-compatible defaults to supply
load-balancer easy-day settings without overriding stored configs.
`loadBalancerContextForNow()` resolves collection
timing once and returns its `daysElapsed`, absolute `nextDayAt` timestamp, and
the cache built for that same day as one immutable result.
`findLoadBalancedIntervalForNow()` builds that context once using its optional
injected `now` and passes the selected preset, nullable note, current interval,
bounds, and optional fuzz seed to the pure
`anki_backend_models.findLoadBalancedInterval()` decision. It returns that
nullable result unchanged and does not apply the answer or mutate cards or the
cache. A caller resolving several answer-button intervals can instead call
`CollectionLoadBalancerContext.reviewIntervalResolver()` with the selected
preset, nullable note, and nullable fuzz seed. The returned
`ReviewLoadBalancerIntervalResolver` reuses that context's existing cache and
`nextDayAt` for every interval, without another collection read or snapshot
copy. `reviewSchedulingContextWithLoadBalancerForNow()` assembles a
`ReviewSchedulingContext` from caller-supplied ordinary scheduler inputs and
Core-resolved preset, nullable note, nullable fuzz seed, and optional clock.
It preserves those inputs and attaches a resolver from one timing/cache
snapshot. Card and preset selection, answer-state transitions, transaction
persistence/undo, scheduler call-site wiring, and Reviewer UI remain outside
this context-assembly method. The post-success in-memory cache-add helper is
available on
`CollectionLoadBalancerContext` once the host has the resulting card and
resolved home config.

`reviewSchedulingContextWithCardLoadBalancerForNow()` accepts a stored card ID,
base scheduler context, load-balancer enablement, nullable answer fuzz seed,
and optional clock. When disabled it returns the base context without reading
the card or collection timing/cache. When enabled it uses the card's original
deck ID when present, otherwise its current deck ID, then selects the stored
deck config. Filtered home decks leave the context unchanged. The config's
`buryReviews` flag controls whether the card note ID is passed to the resolver;
a missing config row retains its config ID and behaves as bury disabled. The
method composes this selection with one timing/cache snapshot and does not
write scheduling state. After a successful answer, a host that already has the
resulting card and resolved home config can call
`CollectionLoadBalancerContext.addAnsweredReviewCard()` to update the context's
in-memory cache. It adds only review-queue cards with a present home config ID;
unknown presets and uncached intervals remain no-ops. The host still owns the
application answer call site, interval application, persistence/undo, and
Reviewer UI.

`currentReviewCardStateForNow()` reads a stored review card and its currently
assigned deck, requires that deck to be normal, and projects its state using
one `timingTodayForNow()` snapshot. The normal-deck due day is clamped to
`min(card.due, daysElapsed)` before projection. Missing cards, missing decks,
non-review cards, and filtered decks produce state errors. Filtered-deck
preview/rescheduling state, learning/relearning state, FSRS derivation,
whole `get_scheduling_states()` composition, answer application and
persistence/cache/undo, and Reviewer UI remain outside this method.

`filteredPreviewSchedulingStatesForCard()` reads the stored card's assigned
deck, requires a non-rescheduling filtered deck, and assembles the current
Preview state plus all four answer outcomes from that deck's stored Again,
Hard, and Good delays. The current state remains unfinished at zero seconds;
zero-delay answers and Easy finish the preview. This is a read-only projection:
it does not resolve scheduler timing, apply answers, or persist card state.

`filteredPreviewSchedulingStatesProtoForCard()` reuses that validated
collection projection and wraps current plus Again/Hard/Good/Easy in generated
`SchedulingStates`, with each state encoded as `SchedulingState.filtered`
containing the `preview` oneof. It preserves `scheduledSecs` and `finished`
exactly and performs no writes.

Filtered-deck search/gathering, rescheduling, normal-state resolution, answer
application, cache updates, transactions/undo, app call-site wiring, and
Reviewer UI remain separate work.

`currentReschedulingFilteredReviewCardStateForNow()` reads a stored Review
card assigned to a filtered deck with rescheduling enabled. It resolves the
effective due day to nonzero `originalDue`, falling back to stored `due`, and
uses that day without normal-deck clamping alongside one
`timingTodayForNow()` snapshot. It returns only the current unwrapped Review
state and reads no deck config, revlogs, FSRS history, or load-balancer
cache/history. Missing cards/decks, non-Review cards, normal decks, and
non-rescheduling filtered decks produce state errors. Filtered rescheduling
execution, other filtered card types, answer-state composition/application,
persistence, transactions/undo, app call-site wiring, and Reviewer UI remain
separate work.

`reschedulingFilteredReviewCardSchedulingStatesForCardForNow()` returns the
current and Again/Hard/Good/Easy states for a stored Review card in a
rescheduling filtered deck. It uses nonzero `originalDue`, otherwise stored
`due`, without normal-deck clamping, and shares one caller-selected timing
snapshot across current state, collection FSRS derivation, and optional load
balancing. The original/home normal deck supplies its config, with Core
defaults when the config row is absent. Each Normal outcome is wrapped in
`SchedulingState.Filtered.ReschedulingFilter.original_state`; Again may map to
Relearn when the caller's context supplies a relearning step. Invalid or
missing cards/decks, normal or non-rescheduling filtered decks, and missing or
invalid home deck/config identity fail clearly. This is read-only: it does not
apply or persist answers. Filtered scheduling execution, answer application,
transactions/undo, app call-site wiring, Preview wrapping, and Reviewer UI
remain separate work.

`currentReschedulingFilteredNewCardState()` reads a stored New card assigned
to a filtered deck with rescheduling enabled. It resolves the current
position from nonzero `originalDue`, otherwise stored `due`, and clamps
negative positions to zero before constructing `NewCardState`. This
read-only projection returns only the current New state; it does not read deck
config, revlogs, or load-balancer cache/history, or calculate answer outcomes.
Missing cards/decks, non-New cards, normal decks, and non-rescheduling filtered
decks produce state errors. Answer-state composition, full filtered
`ReschedulingFilterState` wrapping, other filtered card types, filtered
rescheduling execution, answer application/persistence, transactions/undo,
app call-site wiring, and Reviewer UI remain separate work.

`currentReschedulingFilteredLearningCardState()` reads a stored Learn card
assigned to a filtered deck with rescheduling enabled. The caller supplies
`scheduledSecs` resolved from the current learning step and `elapsedSecs` from
the scheduler timing snapshot; this method does not infer either value from
queue, due, or timestamps. `LearningCardState.fromCard()` preserves those
timings, the stored remaining steps, and memory state. This read-only
projection does not read deck config, revlogs, or load-balancer cache/history.
Missing cards/decks, non-Learn cards, normal decks, and non-rescheduling
filtered decks produce state errors. This closes only current unwrapped Learn
state projection for rescheduling filtered cards; step/timing resolution,
answer-state composition, full filtered `ReschedulingFilterState` wrapping,
other card types, filtered rescheduling execution, answer application and
persistence, transactions/undo, app call-site wiring, and Reviewer UI remain
separate work.

`currentReschedulingFilteredRelearningCardState()` reads a stored Relearn card
assigned to a filtered deck with rescheduling enabled. The caller supplies
`scheduledSecs` from the current relearning step and `elapsedSecs` from the
scheduler timing snapshot; the method does not infer timing from queue, due, or
timestamps. `RelearningCardState.fromCard()` preserves the supplied timings,
remaining steps, and stored Review interval, ease, lapses, and memory state in
the paired current Learning and Review states. This read-only projection does
not read deck config, revlogs, or load-balancer cache/history. Missing
cards/decks, non-Relearn cards, normal decks, and non-rescheduling filtered
decks produce state errors. This closes only current paired Relearn-state
projection for rescheduling filtered cards; step/timing resolution, answer
state composition for Review and other card types, full filtered
`ReschedulingFilterState` wrapping, filtered rescheduling execution, answer
application/persistence, transactions/undo, app call-site wiring, and Reviewer
UI remain separate work.

`reschedulingFilteredRelearningCardSchedulingStatesForCard()` returns generated
`SchedulingStates` for a stored Relearn card in a rescheduling filtered deck.
The caller supplies the current relearning step's `scheduledSecs` and the
matching timing snapshot's `elapsedSecs`; the method does not infer timing
from queue, due, or timestamps. `RelearningCardState.fromCard()` preserves the
paired current Learning and Review states, including remaining steps, Review
interval/ease/lapses, and memory state. Again, Hard, Good, and Easy use the
home deck's config (with Core defaults when its config row is absent) and the
collection FSRS short-term flags composed with caller context. Current and all
answer states are wrapped in the filtered-rescheduling protocol form, including
graduation to Review. Missing or invalid cards, wrong card types, missing
assigned/home decks, normal or non-rescheduling assigned decks, missing home
decks, and invalid home config identities produce state errors. This read-only
API does not read revlogs, FSRS memory history, or load-balancer cache/history,
and does not search/gather, apply answers, or persist scheduling. It closes
stored Relearn answer-state composition for rescheduling filtered decks only;
Review outcomes, Preview wrapping, filtered-card query/gather, rescheduling
execution, answer persistence, transactions/undo, and app/UI wiring remain
open.

`currentReschedulingFilteredCardSchedulingState()` returns the generated
`SchedulingState` filtered-rescheduling wrapper for stored New, Learn, Review,
and Relearn cards. It wraps the existing current-state projections without
changing their due or timing rules: New position and Review effective due use
the filtered-card resolutions above, while Learn and Relearn require explicit
caller-resolved `scheduledSecs` and `elapsedSecs`. It rejects missing cards or
decks, unsupported card types, normal decks, and filtered decks without
rescheduling. This read-only API does not read answer configuration, revlogs,
FSRS history/cache, or mutate collection data. It closes current-state
`ReschedulingFilterState` wrapping for these four stored card types only;
Review answer-state composition, non-rescheduling Preview wrapping,
filtered-card query/gather, rescheduling execution, answer
application/persistence, transactions/undo, and app/UI integration remain open.

`reviewCardSchedulingStatesForCardForNow()` reads a stored normal-deck Review
card and calculates its four answer-button states from a caller-supplied base
`ReviewSchedulingContext`, load-balancer flag, nullable fuzz seed, and optional
clock. It resolves the stored card's assigned normal deck and config, then
projects the normalized config's scheduler fields onto the supplied context.
A missing config row uses Core-compatible defaults; a normal deck with config ID
zero is invalid. Caller-provided fuzz and other dynamic inputs remain intact;
the two FSRS short-term settings come from the collection's global config and
resolved deck parameters. When collection FSRS is enabled, the method reuses or derives
the card's memory state and precomputes all four outcomes from the resolved
parameters, effective desired retention, and last-review time. When load
balancing is enabled, the resolver uses the same config (including
`buryReviews` and its preset ID) and the same timing snapshot as the answer
states. When disabled, the config is still read, but load-balancer
history/cache is not. Missing, non-review, missing-deck, and filtered-deck
errors match `currentReviewCardStateForNow()`. This entry point does not apply
an answer or persist cards/revlogs/cache state. It derives the two FSRS
short-term settings from the global FSRS flags and the same resolved deck
config while preserving other caller-owned dynamic inputs. Filtered-deck
preview/rescheduling, answer application and persistence,
transactions/undo, and Reviewer UI remain outside this entry point.

`newCardSchedulingStatesForCard()` reads a stored new card in a normal deck,
clamps its due position to zero, resolves the deck config (using Core defaults
for a missing row), projects its steps and graduation settings, and derives
the two FSRS short-term flags from collection config. It preserves caller-owned
dynamic context fields and delegates all four buttons to
`NewCardState.nextStates()`. It does not read revlogs or load-balancer history,
derive FSRS memory/outcomes, or persist answers. Missing cards/decks, non-new
cards, filtered decks, and missing deck config IDs are reported as state
errors. Filtered-deck preview/rescheduling, answer application and
persistence, transactions/undo, and Reviewer UI remain outside this entry
point.

`reschedulingFilteredNewCardSchedulingStatesForCard()` reads a stored New card
assigned to a filtered deck with rescheduling enabled. It resolves the current
position from nonzero `originalDue`, falling back to stored `due`, and clamps
negative positions to zero. Again/Hard/Good/Easy are calculated with
`NewCardState.nextStates()` using the original home deck's config and the
collection FSRS short-term flags, while preserving caller-owned dynamic
context. Missing config rows use Core defaults. It returns current and answer
states wrapped in the generated `SchedulingState.Filtered.ReschedulingFilter`
shape. This read-only API rejects missing/invalid cards, missing decks, normal
or non-rescheduling filtered decks, missing original/home decks, and missing
home config IDs. It does not read revlogs, FSRS memory history, or load-balancer
cache/history, and does not apply or persist answers. Learn, Relearn, and
Review outcomes, non-rescheduling Preview wrapping, filtered-card
query/gathering, rescheduling execution, answer persistence, transactions/undo,
and app/UI wiring remain outside this entry point.

`reschedulingFilteredLearningCardSchedulingStatesForCard()` reads a stored
Learn card assigned to a rescheduling filtered deck. The caller supplies
`scheduledSecs` for the current learning step and `elapsedSecs` from the same
scheduler timing snapshot; neither value is inferred from stored queue, due,
or timestamps. `LearningCardState.fromCard()` preserves the stored remaining
steps and FSRS memory, while its four answer transitions use the original
home deck's scheduler config and collection FSRS short-term flags. Missing
config rows use Core defaults, and caller-owned context fields are preserved.
Current and answer Normal states are wrapped in
`SchedulingState.Filtered.ReschedulingFilter.original_state`. The read-only
API rejects missing or invalid cards, missing decks, normal or non-rescheduling
filtered decks, absent original/home decks, and a home deck without a config
ID. It does not read revlogs, FSRS memory history, or load-balancer
cache/history, and does not apply or persist answers. Relearn and Review
filtered outcomes, Preview wrapping, filtered-card query/gathering,
rescheduling execution, answer persistence, transactions/undo, and app/UI
wiring remain outside this entry point.

`learningCardSchedulingStatesForCard()` reads a stored Learn card in its
assigned normal deck and requires `scheduledSecs` and `elapsedSecs` already
resolved from the same scheduler snapshot. It does not infer timing from the
stored queue, due value, or timestamps. The method projects stored remaining
steps and FSRS memory through `LearningCardState.fromCard()`, resolves the
deck's learning/relearning config (using Core defaults for a missing row), and
applies the two collection FSRS short-term flags while preserving caller-owned
context fields. It does not read revlogs or load-balancer history/cache, or
persist answers. Missing cards/decks/config IDs, non-Learn cards, and filtered
decks are reported as state errors.

`relearningCardSchedulingStatesForCard()` reads a stored Relearn card in its
assigned normal deck and requires `scheduledSecs` and `elapsedSecs` already
resolved from the same scheduler snapshot. It does not infer timing from the
stored queue, due value, or timestamps. `RelearningCardState.fromCard()` keeps
the stored remaining steps, interval, ease, lapses, and FSRS memory in Core's
paired current states, then the collection method resolves the deck's
learning/relearning config (using Core defaults for a missing row) and applies
the two collection FSRS short-term flags while preserving caller-owned context
fields. It delegates all four buttons to `nextStates()` and does not read
revlogs or load-balancer history/cache, or persist answers. Missing
cards/decks/config IDs, non-Relearn cards, and filtered decks are reported as
state errors. Filtered-deck preview/rescheduling, answer application and
persistence, transactions/undo, and Reviewer UI remain outside this entry
point.

`reviewCardSchedulingStatesWithCardLoadBalancerForNow()` remains available for
callers that already resolved `ReviewCardState`; those state and base-context
inputs must come from the same host snapshot. It composes only the
card-specific resolver and delegates to `ReviewCardState.nextStates()`.

The storage reader methods are `getCard`, `allCardsOfNote`,
`allCardIdsOfNoteInTemplateOrder`, `getNote`, `getNoteWithoutFields`, and
`getAllNoteIds`. Missing single rows return `null`; collection queries return
empty lists or sets. Only `allCardIdsOfNoteInTemplateOrder` orders by template
ordinal, matching Anki Core. Card JSON conversion preserves Anki's invalid-data
defaults, and note fields and tags use Anki's stored separators.

Card mutation methods are `updateCard`, `addCard`, `addCardIfUnique`,
`addOrUpdateCard`, and `removeCard`. They preserve Anki Core's row columns,
bind order, compact card-data JSON, ID collision allocation, insert-or-ignore
result, and SQLite error and transaction behavior. `addCard` returns the
assigned ID because the shared `Card` model is immutable. It uses the current
millisecond timestamp as the proposed row ID, allocating `max(id) + 1` on a
collision, while persisting the card's supplied `mod` value. These methods do
not create notes, schedule cards, or add transaction boundaries; callers own
transactions.

Note mutation methods are `updateNote`, `addNote`, `addNoteIfUnique`,
`addOrUpdateNote`, and `removeNote`. They delegate to the shared
`anki_backend_storage.NoteStorage` implementation, preserving its prepared-note
preconditions, SQL statements, generated timestamp IDs, and mutable note-ID
assignment. The collection adapter shares its bounded prepared-statement cache
and flushes after autocommit writes; calls inside caller transactions wait for
the transaction boundary. Generated row IDs are read through SQLite's result
path so Web builds retain exact 64-bit values above JavaScript's safe integer
range. `CollectionSqliteStorage.open` accepts an optional `nowMillis` override
for deterministic tests; normal callers omit it to use the system clock.

Editor saves of existing notes should use `updateExistingNote`, which applies
Core's semantic no-op check, stored notetype and configured NFC preparation,
tag canonicalization, modified metadata, normal/cloze card generation, and
collection timestamp update in one savepoint. Its result reports the updated
note, newly generated cards, and an `UpdatedNoteUndoRecord` containing the old
note, prior collection modification timestamp, and tag names newly registered
by the operation. Note edits and callback-backed collection operations share
one bounded, in-memory 30-entry journal. It coalesces successive
card/tag/config-free edits to the same note within Core's 60-second window and
replays the note, generated cards, tags, `nextPos` config, and collection
timestamp. Undoable SQL transactions capture inverse SQLite changesets for
primary-key collection tables, with typed row categories exposed for card,
note, deck, tag, revlog, config, collection, notetype, and custom rows. Deck
deletion keeps its explicit callback inverse for Core's keyless graves table.
Custom restore points can merge subsequent undo steps. Writes through the adapter's
async mutation methods clear the journal. Direct writes through exposed
substores and enclosing transactions must call
`discardExistingNoteUpdateUndoHistory()`. Queue answer/answer-undo variants
belong to the later Scheduler/review-session unit; Reviewer feedback remains a
projection until its app call site is added there. Deck Picker normal-deck
creation and rename are also recorded with stable localized labels.
Sync/import callers should continue using the low-level `addOrUpdateNote` and
raw card operations where their replacement semantics are intended.

`removeDeckAndChildren` removes a deck and its descendants in one exclusive,
undoable collection operation. Normal-deck cards and notes left without cards
are deleted with Core-compatible graves and revlog cleanup; filtered-deck cards
return to their original deck, due value, and queue. Deck-specific auxiliary
config is cleared, while Default is emptied and reset to the host-localized
default name in place. The result
contains the requested deck name and deleted-card count. Up to 30 collection
operations can be undone/redone in memory; later external mutations invalidate
stale history, and a post-commit driver-flush error is reconciled against the
committed collection before persistence is retried.

The native entry point uses the bundled SQLite from `sqlite3`:

```dart
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_native.dart';

final database = await CollectionSqliteStorage.open(
  driver: nativeCollectionSqliteDriver(),
  location: selectedCollectionPath,
  options: CollectionSqliteOptions(androidTempStore: isAndroid),
);
```

`location` comes from the host; the package does not choose a directory or
rename, replace, or delete an existing user file. Applications may instead
inject their own `CollectionSqliteDriver` to select a different driver or
driver configuration.

`close()` keeps existing callers source-compatible. Callers that need Anki's
close-time schema downgrade can use `close(desiredVersion: 11, callbacks: ...)`;
the adapter runs the existing schema catalog and callback sequence in one
exclusive transaction, then switches SQLite to delete journal mode. Target 18
is a no-op. `checkpoint()` rejects active transactions, checks SQLite's
checkpoint return code, and awaits the driver's persistence hook. `quickCheckCorrupt()`
returns false only when SQLite reports exactly `ok`, and treats a SQLite error
or any other result as corruption. `optimize()` runs `vacuum; reindex; analyze`
in Anki Core's order. These operations surface errors from the selected SQLite
driver; the adapter does not silently mask driver-specific unsupported WAL or
maintenance behavior.

Before schema inspection, `CollectionSqliteOptions.configureConnection` can
register additional host-owned functions and collations. Anki Core's current
SQLite configuration includes `field_at_index`, `regexp`, `regexp_fields`,
`regexp_tags`, `process_text`, `fnvhash`, the CardData and FSRS extractors, and
the Unicode-aware `unicase` collation. This package installs all of those on
every opened connection, including both FSRS retrievability functions and
`unicase` before schema inspection. The regex adapter follows locked Rust regex
1.11.2 behavior. A host can use the callback for extra app-specific SQL
functions.

The adapter applies the source connection settings: zero busy timeout,
exclusive locking, 4096-byte page size, a 40 MiB SQLite page cache, the source
legacy-file-format setting, and WAL. It maintains a bounded 50-entry prepared
statement cache for the hot transaction controls (`BEGIN EXCLUSIVE` and
`COMMIT`) and note mutation statements. Schema probes, integrity checks,
rollback, and SQL batches use direct query/execute APIs in the source too, so
the adapter does not retain those statements. Set `androidTempStore` on
Android to use memory for temporary tables. The adapter implements Core's `field_at_index`,
`process_text`, `fnvhash`, all CardData/FSRS extraction scalar functions,
`regexp`, `regexp_fields`, and `regexp_tags`, and the `unicase` collation.
The `decks` and `revlog` properties expose portable deck and review-log row
operations on the opened collection connection through
`anki_backend_storage`.
Undo/redo, media indexing, APKG restore, synchronization, and encryption remain
outside this package's current scope. `CollectionSqliteStorage.exportApkg()`
creates an option-adjusted detached collection, writes current and schema-11
SQLite databases, gathers referenced media through the injected portable media
adapter, and returns a complete APKG byte buffer. Native and Web drivers
provide isolated export copies; the operation never mutates the live
collection. Callers remain responsible for choosing the destination and
publishing or sharing the returned bytes.

`sqlite3` publishes native bindings for Android, iOS, Windows, macOS, and
Linux. Its WebAssembly target is tested in the package CI with
`tool/web_compile_smoke.dart`. The optional `anki_collection_sqlite_web.dart`
entry point configures SQLite with an IndexedDB-backed virtual file system and
an explicit `flush()` hook; it is marked experimental by sqlite3 and does not
guarantee crash durability. Do not treat that Web driver as validated durable
collection storage. A host requiring durable Web collections must provide a
separately validated driver that implements the same injected boundary.

The adapter depends on [`sqlite3` 3.9.1](https://pub.dev/packages/sqlite3).
Its package documentation lists native targets as Android, iOS, Linux, macOS,
and Windows; its separate WebAssembly implementation is explicitly marked
experimental.

Run the real file-backed adapter tests with `dart test`. Compile the
Web-compatible API and experimental persistent-storage setup with:

```sh
dart compile js tool/web_compile_smoke.dart -o /tmp/anki_collection_sqlite.js
```

`tool/web_persistence_smoke.dart` is a browser smoke test that writes and
reopens the IndexedDB-backed collection, snapshots and reopens the snapshot in
an independent Wasm database, verifies later source writes do not alter the
snapshot, and writes/reopens/streams media through IndexedDB. Compile it with
`dart compile js` and serve it with a matching `sqlite3.wasm` asset to exercise
the Web path in a browser. The smoke also exports a real APKG in the browser
and checks both SQLite database versions and the portable media package.

`tool/database_check_web_smoke.dart` exercises the shared database-check
operation against the IndexedDB Web driver. It verifies the orphan-card repair
and incomplete-result contract in the browser. The operation also ports the
currently supported Core card, deck, note-field, revlog, position, and ID
repairs; other Core note/card repairs and app UI integration remain open.

`CollectionSqliteStorage.exportText()` generates an in-memory Notes or Cards
TSV export for the whole collection or a deck and its descendants. It returns
text and a record count; it does not save or share a file. Text formatting
follows Anki Core's pinned export headers, optional note columns, field padding,
HTML option, and tab-delimited quoting. The source mapping is recorded in
`NOTICE.md` and `SOURCE.sha256`.
