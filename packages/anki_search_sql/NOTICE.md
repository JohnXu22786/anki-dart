# Source and license notice

The supported SQL compilation behavior is adapted from
`rslib/src/search/sqlwriter.rs`, `rslib/src/search/parser.rs`,
`rslib/src/storage/sqlite.rs`,
`rslib/src/timestamp.rs`, `rslib/src/card/mod.rs`, `rslib/src/text.rs`,
`rslib/src/decks/name.rs`, `rslib/src/decks/mod.rs`,
`rslib/src/storage/deck/mod.rs`, and `rslib/src/storage/deckconfig/mod.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). Their exact SHA-256 values
are listed in `SOURCE.sha256`. The upstream files are Copyright Ankitects Pty Ltd and contributors and are licensed under the GNU Affero General Public License, version 3 or later.

The Dart compiler and tests are Copyright (C) 2026 John Tsui and distributed
under AGPL-3.0-or-later. The compiler accepts the shared AST from
`anki_search_parser`, supports name matching for decks, deck ID searches with
host-supplied child expansions, deck-preset searches using exact-name
host-supplied deck-config resolution and current/original deck IDs, notetypes
and card templates,
tag predicates in normal, regex, and no-combining modes, unqualified regex
searches with host-supplied field visibility and optional NFC normalization,
unqualified text, no-combining, and cloze-stripped searches with host-supplied
field ranges, accent configuration, and cloze notetype IDs,
state predicates using Core's `CardType` and `CardQueue` numeric values, day
predicates using Core's previous-day cutoffs, rated searches and rated/reschedule properties
using Core's revlog cutoffs and ease filters, basic due/position/interval/reps/
lapses/ease property predicates, FSRS stability, difficulty and retrievability
property predicates, and custom-data existence and numeric/string property
predicates. Rated predicates use explicit next-day timing and checked signed
64-bit timestamp arithmetic. Due properties use explicit collection day and
next-day timing, Core's original-due fallback and integer division, and card
queue values. Ease properties preserve Core's float32 multiplication and
unsigned cast behavior. Stability and Difficulty properties preserve Core's
FSRS variable calls, float32 SQL spelling, and float32 Difficulty transform.
Retrievability preserves Core's timing argument order, New-card false branch,
and original-due fallback. The custom-data predicates preserve Core's SQL
clauses, float32 value spelling, and bound key/value argument order. It uses no
platform-specific database package and does not implement field text matching,
the FSRS SQL functions, or search execution. The repository root `COPYING`
file remains unchanged.
