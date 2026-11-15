// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

/// Portable collection schema catalog and open/create orchestration.
///
/// This package does not provide a SQLite driver or implement source-side
/// migration and default-data callbacks. A host supplies database and callback
/// adapters to execute the catalogued plans and open/create sequence.
library;

export 'src/collection_schema.dart';
export 'src/collection_open.dart';
export 'src/migration_runner.dart';
