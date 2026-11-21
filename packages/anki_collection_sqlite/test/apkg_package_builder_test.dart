// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:convert';
import 'dart:typed_data';

import 'package:anki_backend_protocol/anki/import_export.pb.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:pure_zstd/pure_zstd.dart';
import 'package:test/test.dart';

void main() {
  const database = [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65];
  const compatibilityDatabase = [0x53, 0x51, 0x4c, 0x31, 0x31];

  test('latest package carries compressed database and protobuf metadata', () {
    final bytes = ApkgPackageBuilder.build(
      collectionDatabase: Uint8List.fromList(database),
      compatibilityDatabase: Uint8List.fromList(compatibilityDatabase),
    );
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);

    expect(
      archive.files.map((file) => file.name),
      containsAll(['meta', 'collection.anki21b', 'collection.anki2', 'media']),
    );
    expect(
      PackageMetadata.fromBuffer(
        archive.findFile('meta')!.content as List<int>,
      ).version,
      PackageMetadata_Version.VERSION_LATEST,
    );
    expect(
      zstdDecode(
        Uint8List.fromList(
          archive.findFile('collection.anki21b')!.content as List<int>,
        ),
      ),
      database,
    );
    expect(
      MediaEntries.fromBuffer(
        zstdDecode(
          Uint8List.fromList(archive.findFile('media')!.content as List<int>),
        ),
      ).entries,
      isEmpty,
    );
  });

  test(
    'media uses numbered members with original names and SHA-1 metadata',
    () {
      final media = Uint8List.fromList([0, 1, 2, 255]);
      final bytes = ApkgPackageBuilder.build(
        collectionDatabase: Uint8List.fromList(database),
        compatibilityDatabase: Uint8List.fromList(compatibilityDatabase),
        mediaFiles: {'音声.mp3': media},
      );
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final metadata = MediaEntries.fromBuffer(
        zstdDecode(
          Uint8List.fromList(archive.findFile('media')!.content as List<int>),
        ),
      );

      expect(
        zstdDecode(
          Uint8List.fromList(archive.findFile('0')!.content as List<int>),
        ),
        media,
      );
      expect(metadata.entries, hasLength(1));
      expect(metadata.entries.single.name, '音声.mp3');
      expect(metadata.entries.single.size, media.length);
      expect(metadata.entries.single.sha1, sha1.convert(media).bytes);
    },
  );

  test('legacy package uses plain collection and numbered JSON media map', () {
    final bytes = ApkgPackageBuilder.build(
      collectionDatabase: Uint8List.fromList(database),
      compatibilityDatabase: Uint8List.fromList(compatibilityDatabase),
      mediaFiles: {
        'a.ogg': Uint8List.fromList([8]),
      },
      legacy: true,
    );
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);

    expect(
      PackageMetadata.fromBuffer(
        archive.findFile('meta')!.content as List<int>,
      ).version,
      PackageMetadata_Version.VERSION_LEGACY_2,
    );
    expect(archive.findFile('collection.anki2'), isNotNull);
    expect(archive.findFile('collection.anki21')!.content, database);
    expect(
      jsonDecode(utf8.decode(archive.findFile('media')!.content as List<int>)),
      {'0': 'a.ogg'},
    );
  });

  test('unsafe media name fails without returning an artifact', () {
    expect(
      () => ApkgPackageBuilder.build(
        collectionDatabase: Uint8List.fromList(database),
        compatibilityDatabase: Uint8List.fromList(compatibilityDatabase),
        mediaFiles: {
          for (final name in [
            '../secret',
            'CON.txt',
            'trailing.',
            'e\u0301.mp3',
            'a:b',
          ])
            name: Uint8List.fromList([1]),
        },
      ),
      throwsArgumentError,
    );
  });
}
