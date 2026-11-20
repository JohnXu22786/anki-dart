/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';

import 'package:anki_app/text_export_delivery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Web Save starts a browser download and IndexedDB keeps the pending export',
    () async {
      final delivery = PlatformTextExportDelivery();
      final artifact = TextExportArtifact(
        fileName: 'notes.txt',
        text: 'field\n',
        bytes: Uint8List.fromList(utf8.encode('field\n')),
      );

      expect(await delivery.save(artifact), isTrue);
      final pendingStore = PendingTextExportStore();
      final id = await pendingStore.put(artifact);
      await pendingStore.close();
      final restoredStore = PendingTextExportStore();
      final restored = await restoredStore.get(id);
      expect(restored?.fileName, 'notes.txt');
      expect(restored?.bytes, utf8.encode('field\n'));
      await restoredStore.remove(id);
      await restoredStore.close();
    },
    skip: !kIsWeb,
  );
}
