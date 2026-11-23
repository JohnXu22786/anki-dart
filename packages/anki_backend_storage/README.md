# Anki backend storage

Portable SQL persistence operations for Anki collection models. The package
keeps driver setup, transactions, and connection ownership behind injected
database interfaces, so a host can use the same operations with native SQLite
or a Web-compatible SQLite implementation.

`NoteStorage` ports note-row mutations. `DeckStorage` ports deck row reads and
mutations, including protobuf `common` and tagged `kind` columns, native
`\x1f`-separated names, current-time ID allocation with collision fallback,
upserts, hierarchy reads, and missing-deck detection. `DeckConfigStorage`
ports deck configuration row reads, mutations, protobuf encoding, and
Core-compatible read-time numeric validation. `TagStorage` ports tag row reads,
updates, expanded state, and pending-sync USN selection. Tag parsing and
service-level tree/rename policy, configuration policy, and collection
transaction policy remain separate. `RevlogStorage` ports revlog row insertion,
collision allocation, reads and search-result queries, export filtering,
pending-USN clearing, invalid-property repair, and Core-compatible last-review
timestamps. `CollectionSqliteStorage` adapts these row stores to its native or
Web-compatible common database connection.

Run `python3 tool/check_package.py` to verify pinned source hashes and package
license metadata.
