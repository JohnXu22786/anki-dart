# Source and license notice

This package ports only the Anki Core Card and Note domain values and protobuf
conversions from `rslib/src/card/mod.rs`, `rslib/src/card/service.rs`, and
`rslib/src/notes/mod.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The upstream source is
copyright Ankitects Pty Ltd and contributors and licensed under the GNU Affero
General Public License, version 3 or later. `SOURCE.sha256` records digests of
the exact upstream source files.

The package's Dart implementation is distributed under the same AGPL-3.0-or-
later license. `Note.new()` is not included because upstream creates its GUID
with Notetype-adjacent base91 random generation; protobuf conversion and the
representable stored Note values are included. This package does not change
the root `COPYING` file.
