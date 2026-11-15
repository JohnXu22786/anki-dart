# Source and license notice

This package ports the Anki Core Card and Note domain values and protobuf
conversions from `rslib/src/card/mod.rs`, `rslib/src/card/service.rs`, and
`rslib/src/notes/mod.rs`; Notetype, NoteField and CardTemplate values and
conversions from `rslib/src/notetype/mod.rs`, `rslib/src/notetype/service.rs`,
`rslib/src/notetype/fields.rs`, and `rslib/src/notetype/templates.rs`; Deck
values and conversions from `rslib/src/decks/mod.rs`, `rslib/src/decks/name.rs`,
and `rslib/src/decks/service.rs`; and DeckConfig values and conversions from
`rslib/src/deckconfig/mod.rs` and `rslib/src/deckconfig/service.rs`; media
metadata values from `rslib/src/media/mod.rs` and
`rslib/src/sync/media/database/client/mod.rs`; and collection config entry and
scheduler version values from `rslib/src/config/mod.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The upstream source is
copyright Ankitects Pty Ltd and contributors and licensed under the GNU Affero
General Public License, version 3 or later. `SOURCE.sha256` records digests of
the exact upstream source files.

The package's Dart implementation is distributed under the same AGPL-3.0-or-
later license. Random-value constructors use an injected unsigned 64-bit
source so results remain deterministic and platform neutral:
`Note.newNote()` encodes a base91 GUID, while `NoteField.newField()` and
`CardTemplate.newTemplate()` assign the upstream random config IDs.
`Notetype.ankiDefault()`, `Notetype.defaultConfig()`, and
`Notetype.clozeConfig()` include the pinned default CSS and LaTeX header/footer
assets recorded in `SOURCE.sha256`. `StockNotetypeFactory` implements Anki
Core's localized Basic, Basic (type answer), Basic (and reversed), Basic
(optional reversed), Cloze, and Image Occlusion note types, while accepting
translated names from its caller. Image Occlusion collection operations and
bundled stock-name translation catalogs remain outside this slice. Field and
template name cleanup, NFC normalization, and duplicate-name suffixing also
follow the pinned notetype sources. Name uniqueness uses full Unicode 15.1.0
case folding from `Unicode 15.1.0 CaseFolding.txt`, recorded in
`UNICODE_CASEFOLD.sha256` and covered by the repository's Unicode License V3
text in `LICENSES/Unicode-License-V3.txt`. Deck and DeckConfig models cover
stored values and protobuf conversion. Anki Core's DeckConfig defaults are
provided explicitly. This package does not change the root `COPYING` file.
