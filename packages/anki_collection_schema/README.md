# Anki collection schema catalog

A platform-neutral, AGPL-3.0-or-later catalog of the Anki Core collection
schema and migration sequence pinned in `NOTICE.md`.

`collectionSchema11Sql` creates the source starting schema. The upgrade catalog
contains the ordered SQL and callback operations through schema 18, and the
supported schema 18 to 11 downgrade. `collectionSchemaVersionStatus()` retains
the source's too-old/too-new compatibility outcomes, including rejection of
versions 12 and 13 as too new.

This is a schema-definition slice. It does not open collections, execute SQL,
manage transactions, implement callback transformations, or provide CRUD. A
storage adapter must execute the plan atomically with an appropriate SQLite
executor and supply the named callbacks, including the server-mode argument
where marked.

To verify the source hashes against the pinned Anki Core checkout:

```sh
python3 tool/verify_source.py /path/to/anki-core
```
