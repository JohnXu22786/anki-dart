# Anki search SQL subset

This AGPL-3.0-or-later package compiles a bounded subset of the typed AST from
`anki_search_parser` to source-compatible Anki SQL. It supports boolean
operators, groups, negation, card and note IDs, notetype IDs and names, card
template ordinals and names, tag predicates in normal, regex, and no-combining
modes, deck IDs without children, card flags, all card state predicates, and
whole-collection queries. It preserves source table selection and card/note
SELECT shapes. Unsupported AST nodes throw explicitly.
ID-list AST values follow the shared parser's comma-separated decimal-digit
grammar, and their exact spelling is preserved without numeric conversion.

The compiler is pure Dart, deterministic, and platform-neutral. It does not
execute SQL. The compiler preserves the upstream Unicode-decimal ID spelling
in generated SQL; SQLite may reject such a query, as in the pinned writer.
Field text matching, other regex/glob searches, sorting, browser tables,
database execution, and UI remain outside this package; this subset is not
complete Anki search execution. Tag predicates require the notes table and
preserve Core's `none`, `*`, space, wildcard, case-insensitive regex, and
no-combining `process_text` SQL behavior. Regex function registration remains
the host's responsibility. State predicates require the cards table. A
`state:due` predicate also requires explicit `SearchSqlTiming` values when
calling `compileSearchSql`: `daysElapsed` is the collection day number,
`now` is a `BigInt` containing Unix seconds, and `learnAheadSecs` is the
learning cutoff in seconds. `daysElapsed` and `learnAheadSecs` follow Core's
unsigned 32-bit ranges, and an overflowing signed 64-bit `now + learnAheadSecs`
is rejected. The pinned state SQL uses
`daysElapsed`, `now`, and `learnAheadSecs`; Core's `next_day_at` is not used by
this predicate. No timing is read from a collection or system clock.

Run `dart pub get`, `dart format --output=none --set-exit-if-changed lib test tool`,
`dart analyze lib test tool`, and `dart test`. For JavaScript ID precision,
compile `tool/compile_smoke.dart` with `dart compile js` and run it with Node.
