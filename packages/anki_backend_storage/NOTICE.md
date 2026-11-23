# Source and license notice

This package ports note row updates, inserts, insert-if-unique, insert-or-
replace, and deletion from Anki Core's `rslib/src/storage/note/mod.rs` and the
four matching SQL templates. It also ports Deck reads, inserts, updates,
insert-or-replace, and deletion from `rslib/src/storage/deck/mod.rs` and its
SQL templates, using native deck-name conversion from `rslib/src/decks/name.rs`
and model conversion from `rslib/src/decks/service.rs`. Descendant range reads
and missing-deck detection follow `rslib/src/storage/deck/mod.rs` and
`missing-decks.sql`. The source hashes for these files are recorded in
`SOURCE.sha256`. Existing Anki `notes` and `decks`
table layouts are retained; no schema migration is made.

Copyright: Ankitects Pty Ltd and contributors. Source is licensed under the
GNU Affero General Public License, version 3 or later. The Dart package and
tests retain that license and identify their source through `SOURCE.sha256`.

Deck configuration row reads, mutations, and SQL are adapted from
`rslib/src/storage/deckconfig/mod.rs` and its SQL templates. Read-time bounds
repair follows `rslib/src/deckconfig/mod.rs`; schema-14 upgrade SQL records the
persisted table shape. All pinned source hashes are listed in `SOURCE.sha256`.

Tag row reads and mutations follow `rslib/src/storage/tag/mod.rs` and its SQL
templates; `Tag` values come from `rslib/src/tags/mod.rs`, and pending-sync
USN clauses follow `rslib/src/storage/sync.rs`. Schema-17 tags table shape and
pinned source digests are recorded in `SOURCE.sha256`.

Revlog row reads, inserts, collision allocation, searched-card queries, export
filtering, sync-USN clearing, invalid-property repair, and last-review
timestamps follow `rslib/src/storage/revlog/mod.rs` and its SQL templates. The
revlog table shape is from `rslib/src/storage/schema11.sql`; all pinned source
digests are recorded in `SOURCE.sha256`.
