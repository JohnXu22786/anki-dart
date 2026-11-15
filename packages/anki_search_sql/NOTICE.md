# Source and license notice

The supported SQL compilation behavior is adapted from
`rslib/src/search/sqlwriter.rs`, `rslib/src/search/parser.rs`,
`rslib/src/card/mod.rs`, and `rslib/src/text.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). Their exact SHA-256 values
are listed in `SOURCE.sha256`. The upstream files are Copyright Ankitects Pty Ltd and contributors and are licensed under the GNU Affero General Public License, version 3 or later.

The Dart compiler and tests are Copyright (C) 2026 John Tsui and distributed
under AGPL-3.0-or-later. The compiler accepts the shared AST from
`anki_search_parser`, supports name matching for notetypes and card templates,
tag predicates in normal, regex, and no-combining modes, and state predicates
using Core's `CardType` and `CardQueue` numeric values. It uses no
platform-specific database package and does not implement field text matching
or search execution. The repository root `COPYING` file remains unchanged.
