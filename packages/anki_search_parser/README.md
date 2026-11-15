# Anki search parser

This AGPL-3.0-or-later package ports the Anki Core search query grammar into
platform-neutral Dart. It produces a typed AST for boolean grouping, text and
field searches, built-in search terms, properties, and parser errors. Field
search modes convert to the checked-in `anki_backend_protocol` enum.

The package covers parsing and AST values only. SQL generation, collection
search execution, Browser table rendering and ordering remain unported. The
common parser has no Flutter or `dart:io` dependency. IDs use `fixnum.Int64` so
64-bit values remain exact on Dart VM and compiled JavaScript.

Run `dart pub get`, `dart format --output=none --set-exit-if-changed lib test tool`,
`dart analyze lib test tool`, `dart test`, and `python3 tool/check_package.py`.
The JS smoke check is `dart compile js tool/compile_smoke.dart -o /tmp/search.js`
followed by `node /tmp/search.js`.
