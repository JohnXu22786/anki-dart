# Source and generated-code notice

The protobuf schema source in `proto/anki/` is from Anki Core, repository
`https://github.com/ankitects/anki`, pinned to commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. All 25 schema files are included
verbatim and remain under the GNU Affero General Public License, version 3 or
later. The 24 upstream per-file headers identify Ankitects Pty Ltd and
contributors; those schemas retain their license headers. `ankidroid.proto` has no per-file header in the pinned source; its
AGPL-3.0-or-later identifier is recorded in `proto/SOURCE.sha256` alongside its
exact source digest. The package checker verifies every manifest identifier,
upstream header where present, and source digest without editing schema bytes.

The Dart files in `lib/anki/` are generated from these schemas by Protocol
Buffers compiler 29.3 and Dart `protoc_plugin` 21.1.2. The generator adds an
AGPL SPDX tag to every generated file. The copied `.proto` sources retain
their exact upstream bytes, and the package checker verifies their manifest
SPDX identifiers, upstream headers where present, and rejects non-AGPL tags.
Regenerate with
`tool/generate.sh`; do not edit generated files by hand.

The root `anki_dart` package remains independently licensed under GPL-3.0-or-
later and does not depend on this package. This protocol package does not
change the repository's root `COPYING` file.
