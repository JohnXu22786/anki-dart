#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

PROTOC_VERSION=29.3
PROTOC_PLUGIN_VERSION=21.1.2
PACKAGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_ROOT="$PACKAGE_ROOT/proto"

if ! command -v protoc >/dev/null 2>&1; then
  echo "protoc $PROTOC_VERSION is required" >&2
  exit 1
fi
if [[ "$(protoc --version)" != "libprotoc $PROTOC_VERSION" ]]; then
  echo "Expected libprotoc $PROTOC_VERSION, found $(protoc --version)" >&2
  exit 1
fi

# Pin the generator to the version used by this package's checked-in output.
dart pub global activate protoc_plugin --version "$PROTOC_PLUGIN_VERSION"
if ! dart pub global list | grep -Fxq "protoc_plugin $PROTOC_PLUGIN_VERSION"; then
  echo "protoc_plugin $PROTOC_PLUGIN_VERSION was not activated" >&2
  exit 1
fi
PLUGIN="${PUB_CACHE:-$HOME/.pub-cache}/bin/protoc-gen-dart"
if [[ ! -x "$PLUGIN" ]]; then
  echo "protoc-gen-dart not found at $PLUGIN" >&2
  exit 1
fi

schema_count=$(find "$PROTO_ROOT/anki" -maxdepth 1 -type f -name '*.proto' | wc -l | tr -d ' ')
if [[ "$schema_count" != 25 ]]; then
  echo "Expected all 25 pinned Anki schemas, found $schema_count" >&2
  exit 1
fi

mapfile -t schemas < <(find "$PROTO_ROOT/anki" -maxdepth 1 -type f -name '*.proto' | sort)
relative_schemas=()
for schema in "${schemas[@]}"; do
  relative_schemas+=("${schema#"$PROTO_ROOT/"}")
done
protoc \
  --plugin="protoc-gen-dart=$PLUGIN" \
  --dart_out="$PACKAGE_ROOT/lib" \
  -I "$PROTO_ROOT" \
  "${relative_schemas[@]}"
python3 "$PACKAGE_ROOT/tool/normalize_generated.py"
