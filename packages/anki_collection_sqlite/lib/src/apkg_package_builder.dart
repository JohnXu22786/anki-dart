// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:convert';
import 'dart:typed_data';

import 'package:anki_backend_protocol/anki/import_export.pb.dart' as protocol;
import 'package:anki_backend_protocol/anki/import_export.pbenum.dart'
    as protocol_enum;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'portable_package_io.dart';
import 'zstd_frame.dart';

/// Builds the ZIP container used by Anki's APKG package formats.
///
/// [collectionDatabase] must already contain the filtered, option-adjusted
/// collection. [compatibilityDatabase] is the schema 11 collection included
/// for compatibility as `collection.anki2`. Media keys are the original safe
/// collection filenames.
final class ApkgPackageBuilder {
  const ApkgPackageBuilder._();

  /// Returns a complete in-memory `.apkg` file.
  ///
  /// The current format stores the collection database and media protobuf in
  /// Zstandard frames. Legacy mode emits the uncompressed legacy layout.
  static Uint8List build({
    required Uint8List collectionDatabase,
    required Uint8List compatibilityDatabase,
    Map<String, Uint8List> mediaFiles = const {},
    bool legacy = false,
  }) {
    final archive = Archive();
    final orderedMedia = mediaFiles.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    for (var index = 0; index < orderedMedia.length; index++) {
      final entry = orderedMedia[index];
      _validateApkgMediaFilename(entry.key);
      if (entry.value.length > 0xffffffff) {
        throw ArgumentError.value(
          entry.value.length,
          'mediaFiles[${entry.key}]',
          'Anki media size exceeds uint32',
        );
      }
      archive.addFile(
        ArchiveFile.bytes(
          '$index',
          legacy ? entry.value : encodeZstandardFrame(entry.value),
        ),
      );
    }

    archive.addFile(
      ArchiveFile.bytes('collection.anki2', compatibilityDatabase),
    );

    archive.addFile(
      ArchiveFile.bytes(
        'meta',
        protocol.PackageMetadata(
          version: legacy
              ? protocol_enum.PackageMetadata_Version.VERSION_LEGACY_2
              : protocol_enum.PackageMetadata_Version.VERSION_LATEST,
        ).writeToBuffer(),
      ),
    );

    if (legacy) {
      archive.addFile(
        ArchiveFile.bytes('collection.anki21', collectionDatabase),
      );
      archive.addFile(
        ArchiveFile.string(
          'media',
          jsonEncode({
            for (var index = 0; index < orderedMedia.length; index++)
              '$index': orderedMedia[index].key,
          }),
        ),
      );
    } else {
      archive.addFile(
        ArchiveFile.bytes(
          'collection.anki21b',
          encodeZstandardFrame(collectionDatabase),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'media',
          encodeZstandardFrame(
            Uint8List.fromList(
              protocol.MediaEntries(
                entries: [
                  for (final entry in orderedMedia)
                    protocol.MediaEntries_MediaEntry(
                      name: entry.key,
                      size: entry.value.length,
                      sha1: sha1.convert(entry.value).bytes,
                    ),
                ],
              ).writeToBuffer(),
            ),
          ),
        ),
      );
    }

    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }
}

void _validateApkgMediaFilename(String filename) {
  validateAnkiMediaFilename(filename);
  const disallowed = '[]<>:"/?*^\\|';
  if (unorm.nfc(filename) != filename ||
      utf8.encode(filename).length > 120 ||
      filename.endsWith(' ') ||
      filename.endsWith('.') ||
      filename.contains('\u00a0') ||
      filename.runes.any(
        (rune) => rune < 0x20 || disallowed.contains(String.fromCharCode(rune)),
      ) ||
      RegExp(
        r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
        caseSensitive: false,
      ).hasMatch(filename)) {
    throw ArgumentError.value(
      filename,
      'filename',
      'Filename is not safe for an Anki package',
    );
  }
}
