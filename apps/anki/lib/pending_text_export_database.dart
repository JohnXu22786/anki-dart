/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:sembast/sembast.dart';

import 'pending_text_export_database_stub.dart'
    if (dart.library.io) 'pending_text_export_database_io.dart'
    if (dart.library.js_interop) 'pending_text_export_database_web.dart'
    as platform;

Future<Database> openPendingTextExportDatabase() =>
    platform.openPendingTextExportDatabase();
