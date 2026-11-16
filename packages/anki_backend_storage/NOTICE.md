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
