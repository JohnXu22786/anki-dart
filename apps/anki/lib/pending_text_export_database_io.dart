/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openPendingTextExportDatabase() async {
  final cacheDirectory = await getApplicationCacheDirectory();
  await cacheDirectory.create(recursive: true);
  return databaseFactoryIo.openDatabase(
    path.join(cacheDirectory.path, 'pending_text_exports.db'),
  );
}
