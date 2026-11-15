// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

/// Portable collection schema catalog and transactional migration plan runner.
///
/// This package does not open collections, provide a SQLite driver, or
/// implement the source-side migration callbacks. A host supplies database
/// and callback adapters to execute the catalogued plans.
library;

export 'src/collection_schema.dart';
export 'src/migration_runner.dart';
