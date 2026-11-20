/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:sembast_web/sembast_web.dart';

Future<Database> openPendingTextExportDatabase() =>
    databaseFactoryWeb.openDatabase('anki_pending_text_exports');
