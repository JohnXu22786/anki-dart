// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:convert';

/// A driver capability that the selected platform cannot provide.
final class PortableIoUnsupported implements Exception {
  const PortableIoUnsupported(this.capability);
  final String capability;

  @override
  String toString() => 'Portable I/O capability unsupported: $capability';
}

/// Reads and enumerates collection media without exposing platform file APIs.
abstract interface class CollectionMediaStorage {
  Future<Stream<List<int>>?> read(String filename);
  Future<Iterable<String>> list();

  /// Releases adapter handles while retaining its stored media.
  FutureOr<void> close();
}

/// Rejects invalid names at the shared API boundary before platform access.
String validateAnkiMediaFilename(String filename) {
  if (filename.isEmpty ||
      filename == '.' ||
      filename == '..' ||
      filename.contains('/') ||
      filename.contains('\\') ||
      filename.contains(':') ||
      filename.contains('\u0000') ||
      filename.length > 1024 ||
      utf8.encode(filename).length > 1024) {
    throw ArgumentError.value(filename, 'filename', 'Invalid Anki media name');
  }
  return filename;
}
