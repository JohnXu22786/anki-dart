/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'collection_runtime.dart';

Future<CollectionRuntime> createPlatformCollectionRuntime() => Future.error(
  UnsupportedError('Collection SQLite is unsupported on this platform.'),
);
