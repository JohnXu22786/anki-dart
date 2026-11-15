# Source and license notice

This package ports Anki Core Card and Note domain values, protobuf conversions,
field checksum, field normalization, Note::fix_field_count, note preparation,
and HTML/media-aware field text behavior from `rslib/src/card/mod.rs`,
`rslib/src/card/service.rs`, `rslib/src/notes/mod.rs`, and
`rslib/src/text.rs`; field emptiness and Note field-presence behavior from
`rslib/src/template.rs` and `rslib/src/notes/mod.rs`; Notetype, NoteField and
CardTemplate values, conversions,
and default configuration assets from `rslib/src/notetype/mod.rs`,
`rslib/src/notetype/service.rs`, `rslib/src/notetype/fields.rs`,
`rslib/src/notetype/templates.rs`, `rslib/src/notetype/styling.css`,
`rslib/src/notetype/cloze_styling.css`, `rslib/src/notetype/header.tex`,
`rslib/src/notetype/stock.rs`, `rslib/src/image_occlusion/notetype.rs`, and
`rslib/src/image_occlusion/notetype.css`; Deck and DeckConfig values and
conversions from `rslib/src/decks/mod.rs`, `rslib/src/decks/name.rs`,
`rslib/src/decks/service.rs`, `rslib/src/deckconfig/mod.rs`, and
`rslib/src/deckconfig/service.rs`; RevlogId, RevlogEntry, review kind values,
protobuf conversions, and scheduling/statistics helpers from
`rslib/src/revlog/mod.rs`, `rslib/src/stats/service.rs`, and
`proto/anki/stats.proto`; media metadata values from `rslib/src/media/mod.rs`
and `rslib/src/sync/media/database/client/mod.rs`; and collection config entry
and scheduler version values from `rslib/src/config/mod.rs` at commit
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
Core's Basic, Basic (type answer), Basic (and reversed), Basic (optional
reversed), Cloze, and Image Occlusion note types, while accepting translated
names from its caller. Image Occlusion collection operations and bundled
stock-name translation catalogs remain outside this slice. Field and template
name cleanup, NFC normalization, and duplicate-name suffixing follow the
pinned notetype sources. Name uniqueness uses full Unicode 12.1.0 case folding,
matching the generated table embedded by pinned `unicase 2.6.0`, from
`Unicode 12.1.0 CaseFolding.txt`; its digest is recorded in
`UNICODE_CASEFOLD.sha256` and the data is covered by the repository's Unicode
License V3 text at `LICENSES/Unicode-License-V3.txt`. Deck and DeckConfig models
include stored values, conversions, and pinned defaults. Media metadata and
collection configuration values are also included. The HTML named-entity table
in `lib/src/html_entities.dart` is adapted from `htmlescape` 0.3.1 by Viktor
Dahl, licensed under Apache-2.0, MIT, or MPL-2.0; the package includes the
Apache-2.0 license text. Its source digest is recorded in
`THIRD_PARTY_SOURCE.sha256`. This package does not change the root `COPYING`
file.
