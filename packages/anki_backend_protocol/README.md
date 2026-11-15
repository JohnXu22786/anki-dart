# Anki backend protocol for Dart

This is a standalone AGPL-3.0-or-later Dart package containing the official
Anki Core protobuf schemas and generated Dart message, enum, descriptor, and
service-base code. It provides protocol types and protobuf codecs only; it does
not implement collection algorithms, scheduling, storage, synchronization, or
backend transport.

The source schemas in `proto/anki/` are copied verbatim from the Anki Core
repository at commit
[`e64c6b1aee3e8d668fb8bbe084beada8e070d985`](https://github.com/ankitects/anki/tree/e64c6b1aee3e8d668fb8bbe084beada8e070d985/proto/anki).
They retain their original Ankitects Pty Ltd and contributors attribution and
GNU AGPL version 3 or later headers. `proto/SOURCE.sha256` records the digest of
each of the 25 source files. `LICENSE` contains the full GNU AGPL version 3 text;
`NOTICE.md` records source and generation provenance.

## Regenerate

Install `protoc` 29.3 and Dart 3.13.7 or newer, then run from the repository
root:

```sh
packages/anki_backend_protocol/tool/generate.sh
```

The script checks `libprotoc 29.3`, activates `protoc_plugin` 21.1.2, verifies
the complete 25-schema input set, and generates all Dart artifacts from the
checked-in schemas. The generator applies only deterministic trailing-whitespace
normalization after protoc. Do not edit generated Dart by hand. To check whether the
checked-in generated output is current, run the command and inspect
`git diff -- packages/anki_backend_protocol/lib`.

## Validate

From this directory:

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib/anki_backend_protocol.dart test tool
dart analyze lib test tool
dart test
python3 tool/check_package.py
dart compile js tool/compile_smoke.dart -o /tmp/anki_backend_protocol.js
```

The package depends only on the pure Dart `protobuf` runtime. It has no
`dart:io` or platform-channel dependency, so it can be consumed by Dart VM and
Flutter targets including web.
