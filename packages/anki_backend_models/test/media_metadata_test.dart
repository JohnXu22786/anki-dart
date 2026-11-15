// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('media metadata values', () {
    test('SHA-1 digest has fixed 20-byte value semantics', () {
      final bytes = List<int>.generate(20, (index) => index);
      final digest = Sha1Hash(bytes);
      bytes[0] = 99;
      expect(digest.bytes.first, 0);
      expect(digest, Sha1Hash(List<int>.generate(20, (index) => index)));
      expect(digest.hashCode,
          Sha1Hash(List<int>.generate(20, (index) => index)).hashCode);
      expect(() => Sha1Hash([1, 2]), throwsArgumentError);
      expect(() => Sha1Hash([...List<int>.filled(19, 0), 256]),
          throwsArgumentError);
    });

    test('media entry represents live and deleted rows and compares by value',
        () {
      final digest = Sha1Hash(List<int>.filled(20, 7));
      final live = MediaEntry(
        fileName: 'sound.mp3',
        sha1: digest,
        mtime: Int64(123),
        syncRequired: true,
      );
      final equalLive = MediaEntry(
        fileName: 'sound.mp3',
        sha1: Sha1Hash(List<int>.filled(20, 7)),
        mtime: Int64(123),
        syncRequired: true,
      );
      final deleted = MediaEntry(
        fileName: 'sound.mp3',
        sha1: null,
        mtime: Int64.ZERO,
        syncRequired: true,
      );

      expect(live, equalLive);
      expect(live.hashCode, equalLive.hashCode);
      expect(deleted.sha1, isNull);
      expect(deleted.mtime, Int64.ZERO);
      expect(deleted, isNot(live));
    });

    test('database metadata preserves 64-bit mtime and signed 32-bit USN', () {
      final metadata = MediaDatabaseMetadata(
        folderMtime: Int64.parseInt('9007199254740993'),
        lastSyncUsn: 0x100000001,
      );
      expect(metadata.folderMtime, Int64.parseInt('9007199254740993'));
      expect(metadata.lastSyncUsn, 1);
      expect(
        metadata,
        MediaDatabaseMetadata(
          folderMtime: Int64.parseInt('9007199254740993'),
          lastSyncUsn: 1,
        ),
      );
    });

    test('checksum lookup lowercases only the requested filename', () {
      final digest = Sha1Hash(List<int>.filled(20, 1));
      final checksums = Checksums({'image.png': digest});
      expect(checksums.get('IMAGE.PNG'), digest);
      expect(checksums.containsKey('Image.PNG'), isTrue);
      expect(Checksums({'Image.png': digest}).get('Image.png'), isNull);
      expect(
          Checksums({'image.png': digest}).containsKey('missing.png'), isFalse);
    });
  });
}
