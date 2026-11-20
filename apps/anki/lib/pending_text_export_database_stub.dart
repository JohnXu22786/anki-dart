/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:sembast/sembast.dart';

Future<Database> openPendingTextExportDatabase() => Future.error(
  UnsupportedError('Pending text export storage is unavailable.'),
);
