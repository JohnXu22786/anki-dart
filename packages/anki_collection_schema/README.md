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

Only transactional execution of the existing plans is implemented. The
package does not create or open collections, inspect integrity, configure WAL,
implement the named transformation callbacks, provide table CRUD or defaults,
or implement undo or a complete collection engine. Host integrations supply
the database adapter and callback implementations.

To verify the source hashes against the pinned Anki Core checkout:

```sh
python3 tool/verify_source.py /path/to/anki-core
```
