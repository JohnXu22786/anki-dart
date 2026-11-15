// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_schema/anki_collection_schema.dart';

void main() {
  if (collectionSchemaVersionStatus(18) !=
      CollectionSchemaVersionStatus.supported) {
    throw StateError('collection schema package JS smoke compilation failed');
  }
}
