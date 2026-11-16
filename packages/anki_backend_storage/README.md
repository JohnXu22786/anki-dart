# Anki backend storage

Portable SQL persistence operations for Anki collection models. The package
keeps driver setup, transactions, and connection ownership behind injected
database interfaces, so a host can use the same operations with native SQLite
or a Web-compatible SQLite implementation.

`NoteStorage` ports note-row mutations. `DeckStorage` ports deck row reads and
mutations, including protobuf `common` and tagged `kind` columns, native
`\x1f`-separated names, current-time ID allocation with collision fallback,
upserts, and update errors for missing rows. Deck hierarchy, name uniqueness,
DeckConfig persistence, and collection transaction policy remain separate
operations. `CollectionSqliteStorage.decks` adapts the Deck operations to its
native or Web-compatible common database connection.

Run `python3 tool/check_package.py` to verify pinned source hashes and package
license metadata.
