# Anki collection schema catalog

A platform-neutral, AGPL-3.0-or-later catalog of the Anki Core collection
schema and migration sequence pinned in `NOTICE.md`.

`collectionSchema11Sql` creates the source starting schema. The upgrade catalog
contains the ordered SQL and callback operations through schema 18, and the
supported schema 18 to 11 downgrade. `collectionSchemaVersionStatus()` retains
the source's too-old/too-new compatibility outcomes, including rejection of
versions 12 and 13 as too new.

This is a platform-neutral schema and migration package. It includes a
transactional plan runner that executes the catalogued SQL batches and named
callbacks in source order, using an exclusive transaction and attempting
rollback on failure. The runner accepts synchronous or asynchronous host
adapters through `CollectionSchemaMigrationDatabase` and
`CollectionSchemaMigrationCallbacks`; it does not select a SQLite driver.

The package also orchestrates the source open/create sequence through injected
host contracts: it detects an absent collection, rejects incompatible schema
versions, optionally checks integrity, and performs schema 11 creation,
ordered upgrades, and default callbacks in one exclusive transaction. Existing
schema 18 collections are a no-op. The open/create runner reuses the migration
catalog without opening a nested transaction.

The host supplies the database adapter and callbacks. In particular, metadata
initialization supplies the source-compatible clock, version 1 creation date,
local timezone offset, and schema 11 default-config serialization. Named
migration callbacks and default deck/config/note-type creation remain host
responsibilities. This package does not configure WAL, provide a concrete
driver, implement collection CRUD, close/checkpoint a collection, or provide
undo or a complete collection engine.

To verify the source hashes against the pinned Anki Core checkout:

```sh
python3 tool/verify_source.py /path/to/anki-core
```
