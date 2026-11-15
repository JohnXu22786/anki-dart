# Anki search SQL subset

This AGPL-3.0-or-later package compiles a bounded subset of the typed AST from
`anki_search_parser` to source-compatible Anki SQL. It supports boolean
operators, groups, negation, card and note IDs, notetype IDs and names, card
template ordinals and names, tag predicates in normal, regex, and no-combining
modes, unqualified text and regex searches, deck IDs with and without children,
deck-preset predicates, card flags,
all card state predicates, added/edited/introduced day predicates, and
whole-collection queries. It
preserves source table selection and card/note SELECT shapes. Named deck
searches match the deck and its descendants by normalized native path, and
also match the original deck of cards in filtered decks. `deck:*` and
`deck:filtered` use Core's special predicates; `deck:current` accepts an
optional native current-deck name through `currentDeckName`, defaulting to
`Default` when the caller has no current deck record. Supply the native current
deck path with U+001F between components; wildcard characters in it are literal.
`DeckIdWithChildren` accepts a `deckIdsWithChildren` map resolved by the host,
keyed by exact signed 64-bit deck IDs represented as `BigInt`. Each mapped list
is emitted in order in `c.did in (...)`; an absent key emits `false`. This
compiler does not query deck storage or match filtered cards by original deck.
`Preset` accepts a `deckIdsByPreset` map resolved by the host using the exact
deck-config name. The caller looks up the config by name and selects decks in
source order whose `config_id()` matches it. An absent key emits `false`; a
present empty list emits the source-compatible empty `()` membership lists.
Each list is emitted in order for both `c.did` and `c.odid`, so filtered cards
also match their original deck. IDs remain full-width signed 64-bit `BigInt`
values. This compiler does not query deck-config or deck storage, and preset
names are not normalized or case-folded.
Named deck searches use Core's
case-insensitive Anki wildcard regex semantics and component normalization.
Custom-data
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
`prop:s` and `prop:d` use Core's `extract_fsrs_variable(c.data, 's'/'d')`
function calls, float32 SQL rendering, and Difficulty's float32 `value * 9 + 1`
transform. `prop:r` uses Core's `extract_fsrs_retrievability()` arguments and
returns false for New card types; it requires explicit `daysElapsed`,
`nextDayAt`, and `now` timing values, validating their Core integer ranges.
These FSRS properties require the cards table, including distinct note-result
projection through the cards/notes join. The host must register both FSRS SQL
functions; this package does not implement either database function.
Unsupported AST nodes throw explicitly.
ID-list AST values follow the shared parser's comma-separated decimal-digit
grammar, and their exact spelling is preserved without numeric conversion.

The compiler is pure Dart, deterministic, and platform-neutral. It does not
execute SQL. The compiler preserves the upstream Unicode-decimal ID spelling
in generated SQL; SQLite may reject such a query, as in the pinned writer.
Field-qualified search, duplicate detection, remaining glob predicates,
sorting, browser tables, database execution, and UI remain outside this
package; this subset is not complete Anki search execution. Custom-data and state predicates
require the cards table, and the host must register `extract_custom_data()`.
Tag predicates require the notes table and preserve Core's `none`, `*`, space,
wildcard, case-insensitive regex, and no-combining `process_text` SQL behavior.
Regex function registration remains the host's responsibility.
`RegexSearch` requires the notes table and emits
Core's case-insensitive `n.flds regexp` clause without interpreting or changing
the regex. `regexFieldsByNotetype` accepts source-derived notetype IDs, total
field counts, and included field indices from the host; omit it when no fields
are excluded, or pass each notetype context to emit Core's `regexp_fields`
clauses. The compiler does not load a collection or resolve field visibility.
`normalizeNoteText` optionally NFC-normalizes regex patterns and defaults to
false. `TextSearch`, `NoCombining`, and `StripClozes` use source `LIKE` clauses,
including Core's wildcard conversion and field-visibility handling.
`SearchSqlTextContext` supplies the `IgnoreAccentsInSearch` setting, ordered
cloze notetype IDs (required for `StripClozes`, including an explicitly empty
list when no cloze notetypes exist), and (when any field is excluded) the host-resolved ranges
of searchable fields and sort-field visibility. Omitting it searches both
`sfld` and `flds`, with accent folding disabled. Text predicates use the same
`normalizeNoteText` setting for NFC normalization. Their `process_text` flags
match Core's `NoCombining` and `StripClozes` bits; the host must register
`process_text()` and populate context from the same collection snapshot.
State predicates require the cards table. A
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
