# Source and license notice

This package ports the Anki Core Card and Note domain values and protobuf
conversions from `rslib/src/card/mod.rs`, `rslib/src/card/service.rs`, and
`rslib/src/notes/mod.rs`, plus the Notetype, NoteField and CardTemplate values
and protobuf conversions from `rslib/src/notetype/mod.rs`,
`rslib/src/notetype/service.rs`, `rslib/src/notetype/fields.rs`, and
`rslib/src/notetype/templates.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The upstream source is
copyright Ankitects Pty Ltd and contributors and licensed under the GNU Affero
General Public License, version 3 or later. `SOURCE.sha256` records digests of
the exact upstream source files.

The package's Dart implementation is distributed under the same AGPL-3.0-or-
later license. Constructors that depend on randomness or assets are not
included: `Note.new()` creates a base91 GUID, `NoteField.new()` and
`CardTemplate.new()` create random config IDs, and Notetype default
construction includes CSS and LaTeX assets. The models cover stored values and
protobuf conversion; absent proto configs use the generated protocol defaults.
Those constructors are the next required model slice. This package does not
change the root `COPYING` file.
