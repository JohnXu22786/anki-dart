// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

/// Portable catalog of the collection schema pinned in Anki Core.
///
/// This package describes SQL and source-side migration callbacks. It does not
/// open a database, execute SQL, provide SQLite drivers, or implement those
/// callbacks. An adapter must run creation/upgrades transactionally using the
/// operations and order exposed here.
library;

export 'src/collection_schema.dart';
