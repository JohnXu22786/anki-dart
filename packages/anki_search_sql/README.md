# Anki search SQL subset

This AGPL-3.0-or-later package compiles a bounded subset of the typed AST from
`anki_search_parser` to source-compatible Anki SQL. It supports boolean
operators, groups, negation, card and note IDs, notetype IDs and names, card
template ordinals and names, tag predicates in normal, regex, and no-combining
modes, deck IDs without children, card flags, all card state predicates,
added/edited/introduced day predicates, and whole-collection queries. It
preserves source table selection and card/note SELECT shapes. Custom-data
existence and string/number property comparisons use Core's
`extract_custom_data(c.data, ?)` expressions; keys and string values remain
bound arguments, while numeric values use Core-compatible float32 spelling.
Rated searches and `prop:rated`/`prop:resched` comparisons use Core's revlog
subqueries, day cutoffs, operators, and ease filters. They require explicit
`SearchSqlTiming.nextDayAt`; cutoff arithmetic and emitted millisecond values
are checked against signed 64-bit bounds.
Basic `prop:due`, `prop:pos`, `prop:ivl`, `prop:reps`, `prop:lapses`, and
`prop:ease` comparisons use Core's card columns, queue/type codes, original-due
fallback, operators, and float32-to-u32 ease conversion. Due properties
require explicit `SearchSqlTiming.daysElapsed` and `nextDayAt`; no collection
or clock values are read implicitly. These card predicates use cards for card
results and join cards to notes with distinct note IDs for note results.
Unsupported AST nodes throw explicitly.
ID-list AST values follow the shared parser's comma-separated decimal-digit
grammar, and their exact spelling is preserved without numeric conversion.

The compiler is pure Dart, deterministic, and platform-neutral. It does not
execute SQL. The compiler preserves the upstream Unicode-decimal ID spelling
in generated SQL; SQLite may reject such a query, as in the pinned writer.
Field text matching, other regex/glob searches, sorting, browser tables,
database execution, and UI remain outside this package; this subset is not
complete Anki search execution. Custom-data and state predicates require the
cards table, and the host must register `extract_custom_data()`. Tag predicates require the notes table and
preserve Core's `none`, `*`, space, wildcard, case-insensitive regex, and
no-combining `process_text` SQL behavior. Regex function registration remains
the host's responsibility. State predicates require the cards table. A
`state:due`, `rated:`, rated properties, and due properties also require explicit
`SearchSqlTiming` values when
calling `compileSearchSql`: `daysElapsed` is the collection day number,
`now` is a `BigInt` containing Unix seconds, and `learnAheadSecs` is the
learning cutoff in seconds. The `added:`, `edited:`, and `introduced:`
predicates require `nextDayAt`, a `BigInt` containing the collection's
next-day rollover timestamp in Unix seconds, within the signed 64-bit range.
Their day values follow Core's unsigned 32-bit range. Cutoffs and millisecond
conversion are checked against signed 64-bit bounds before exact decimal SQL
values are emitted. An omitted or out-of-range `nextDayAt` is rejected. No
timing is read from a collection or system clock. `state:due` uses the same
explicit timing object with
`daysElapsed` as the collection day number, `now` as Unix seconds, and
`learnAheadSecs` as the learning cutoff in seconds. Those values follow Core's
unsigned 32-bit ranges, and an overflowing signed 64-bit
`now + learnAheadSecs` is rejected.

The plain `rated:` form accepts unsigned 32-bit day counts and uses Core's
`>` comparison against the negated day count. `prop:rated` accepts signed
32-bit nonpositive day counts and uses its supplied comparison operator;
`prop:resched` emits the manual-reschedule (`ease = 0`) rating class. Answer
buttons, any answer (`ease > 0`), and manual rescheduling retain their Core
revlog filters. Rated searches require cards and revlog; note results join
cards to notes and select distinct note IDs.

Run `dart pub get`, `dart format --output=none --set-exit-if-changed lib test tool`,
`dart analyze lib test tool`, and `dart test`. For JavaScript ID precision,
compile `tool/compile_smoke.dart` with `dart compile js` and run it with Node.
