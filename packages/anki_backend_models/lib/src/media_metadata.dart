// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';

/// The fixed-size checksum used by Anki's media database.
class Sha1Hash {
  Sha1Hash(Iterable<int> bytes) : bytes = List.unmodifiable(bytes) {
    if (this.bytes.length != 20) {
      throw ArgumentError.value(
          bytes, 'bytes', 'SHA-1 hashes contain 20 bytes');
    }
    if (this.bytes.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(bytes, 'bytes', 'SHA-1 bytes must be unsigned');
    }
  }

  final List<int> bytes;

  @override
  bool operator ==(Object other) =>
      other is Sha1Hash && _sameBytes(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

/// One local media database row. A null checksum marks a deleted file.
class MediaEntry {
  MediaEntry({
    required this.fileName,
    required this.sha1,
    required this.mtime,
    required this.syncRequired,
  });

  final String fileName;
  final Sha1Hash? sha1;
  final Int64 mtime;
  final bool syncRequired;

  @override
  bool operator ==(Object other) =>
      other is MediaEntry &&
      other.fileName == fileName &&
      other.sha1 == sha1 &&
      other.mtime == mtime &&
      other.syncRequired == syncRequired;

  @override
  int get hashCode => Object.hash(fileName, sha1, mtime, syncRequired);
}

/// Media folder timestamp and last synced collection USN.
class MediaDatabaseMetadata {
  MediaDatabaseMetadata({required this.folderMtime, required int lastSyncUsn})
      : lastSyncUsn = lastSyncUsn.toSigned(32);

  final Int64 folderMtime;
  final int lastSyncUsn;

  @override
  bool operator ==(Object other) =>
      other is MediaDatabaseMetadata &&
      other.folderMtime == folderMtime &&
      other.lastSyncUsn == lastSyncUsn;

  @override
  int get hashCode => Object.hash(folderMtime, lastSyncUsn);
}

/// Checksums indexed by their stored filename with source-compatible lookup.
class Checksums {
  Checksums(Map<String, Sha1Hash> checksums)
      : _checksums = Map.unmodifiable(checksums);

  final Map<String, Sha1Hash> _checksums;

  Sha1Hash? get(String filename) => _checksums[filename.toLowerCase()];

  bool containsKey(String filename) => get(filename) != null;
}
