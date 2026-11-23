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
at the 99-day load-balancer window to keep allocation bounded. Easy-day
configuration, weekday derivation, sibling discovery, weighted selection, and
scheduler execution remain outside this query.

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
