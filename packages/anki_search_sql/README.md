# Anki search SQL subset

This AGPL-3.0-or-later package compiles a bounded subset of the typed AST from
`anki_search_parser` to source-compatible Anki SQL. It supports boolean
operators, groups, negation, card and note IDs, notetype IDs, deck IDs without
children, card flags, and whole-collection queries. It preserves source table
selection and card/note SELECT shapes. Unsupported AST nodes throw explicitly.
ID-list AST values follow the shared parser's comma-separated decimal-digit
grammar, and their exact spelling is preserved without numeric conversion.

The compiler is pure Dart, deterministic, and platform-neutral. It does not
execute SQL. The compiler preserves the upstream Unicode-decimal ID spelling
in generated SQL; SQLite may reject such a query, as in the pinned writer.
Field and tag text matching, regex/glob searches, sorting,
browser tables, database execution, and UI remain outside this package; this
subset is not complete Anki search execution.

Run `dart pub get`, `dart format --output=none --set-exit-if-changed lib test tool`,
`dart analyze lib test tool`, and `dart test`. For JavaScript ID precision,
compile `tool/compile_smoke.dart` with `dart compile js` and run it with Node.
