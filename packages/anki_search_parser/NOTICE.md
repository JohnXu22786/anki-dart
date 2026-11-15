# Source and license notice

This package ports Anki Core search parsing, query building, and canonical
query writing from `rslib/src/search/parser.rs`, `rslib/src/search/builder.rs`,
and `rslib/src/search/writer.rs`, plus the wildcard escaping helper in
`rslib/src/text.rs`, from commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The exact source file
SHA-256 is recorded in `SOURCE.sha256` and checked by `tool/check_package.py`.
The upstream source is copyright Ankitects Pty Ltd and contributors and
licensed under the GNU Affero General Public License, version 3 or later.
The Dart parser and AST are distributed under the same AGPL-3.0-or-later
license. This package does not alter the root GPL `COPYING` file.
