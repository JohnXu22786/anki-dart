/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:sembast/sembast.dart';
import 'package:share_plus/share_plus.dart';

import 'pending_text_export_database.dart';

/// The completed, platform-independent text export passed to Save or Share.
final class TextExportArtifact {
  TextExportArtifact({
    required this.fileName,
    required Uint8List bytes,
    required this.text,
  }) : bytes = List<int>.unmodifiable(bytes);

  final String fileName;
  final List<int> bytes;
  final String text;
  String get mimeType => 'text/plain';

  XFile toXFile() => XFile.fromData(
    Uint8List.fromList(bytes),
    name: fileName,
    mimeType: mimeType,
  );
}

/// Product-level file delivery actions. A false result means the user
/// dismissed the platform UI; thrown errors can be shown and retried.
abstract interface class TextExportDelivery {
  Future<bool> save(TextExportArtifact artifact);
  Future<bool> share(TextExportArtifact artifact);
}

abstract interface class TextFileSaveAs {
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

final class FileSaverTextFileSaveAs implements TextFileSaveAs {
  const FileSaverTextFileSaveAs();

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) => FileSaver.instance.saveAs(
    name: fileName.replaceFirst(RegExp(r'\.txt$'), ''),
    bytes: bytes,
    fileExtension: 'txt',
    mimeType: MimeType.custom,
    customMimeType: mimeType,
  );
}

/// Thin cross-platform adapters; product flow and artifact construction stay
/// shared across Android, iOS, Web, Windows, macOS and Linux.
final class PlatformTextExportDelivery implements TextExportDelivery {
  const PlatformTextExportDelivery({
    this.fileSaveAs = const FileSaverTextFileSaveAs(),
    this.shareRequest = _share,
    this.isLinux = _isLinux,
  });

  final TextFileSaveAs fileSaveAs;
  final Future<ShareResult> Function(ShareParams params) shareRequest;
  final bool Function() isLinux;

  static Future<ShareResult> _share(ShareParams params) =>
      SharePlus.instance.share(params);

  static bool _isLinux() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// The Linux share_plus adapter percent-encodes text into a `mailto:` URI.
  /// Bound the encoded URI (including subject and fixed syntax) conservatively
  /// to avoid desktop URL launcher and mail client limits; users can Save any
  /// artifact within the store's 64 MiB cap.
  static const maxLinuxShareUriCharacters = 8 * 1024;

  @override
  Future<bool> save(TextExportArtifact artifact) async {
    final savedPath = await fileSaveAs.save(
      fileName: artifact.fileName,
      bytes: Uint8List.fromList(artifact.bytes),
      mimeType: artifact.mimeType,
    );
    return savedPath != null;
  }

  @override
  Future<bool> share(TextExportArtifact artifact) async {
    final linux = isLinux();
    final estimatedLinuxUriLength =
        Uri.encodeComponent(artifact.text).length +
        Uri.encodeComponent(artifact.fileName).length +
        32;
    if (linux && estimatedLinuxUriLength > maxLinuxShareUriCharacters) {
      throw const TextExportShareTooLargeException();
    }
    // share_plus on Linux has no file attachment support; its supported
    // mechanism opens a mail composer with the full export as the body.
    final params = ShareParams(
      files: linux ? null : [artifact.toXFile()],
      text: artifact.text,
      title: artifact.fileName,
      subject: artifact.fileName,
      downloadFallbackEnabled: true,
    );
    final result = await shareRequest(params);
    return result.status == ShareResultStatus.success;
  }
}

/// Keeps generated content outside Flutter restoration data. Restoration only
/// stores the small key, avoiding copying a potentially large text export.
final class PendingTextExportStore {
  PendingTextExportStore({
    Future<Database> Function()? openDatabase,
    this.maxArtifactBytes = defaultMaxArtifactBytes,
    this.maxPendingBytes = defaultMaxPendingBytes,
    this.maxPendingEntries = defaultMaxPendingEntries,
    this.maxPendingAge = defaultMaxPendingAge,
  }) : _openDatabase = openDatabase ?? openPendingTextExportDatabase;

  static PendingTextExportStore instance = PendingTextExportStore();
  static const defaultMaxArtifactBytes = 64 * 1024 * 1024;
  static const defaultMaxPendingBytes = 64 * 1024 * 1024;
  static const defaultMaxPendingEntries = 16;
  static const defaultMaxPendingAge = Duration(days: 7);
  static final _random = Random.secure();
  static final _store = stringMapStoreFactory.store('pending_text_exports');
  final int maxArtifactBytes;
  final int maxPendingBytes;
  final int maxPendingEntries;
  final Duration maxPendingAge;
  final Future<Database> Function() _openDatabase;
  Future<Database>? _database;

  Future<String> put(TextExportArtifact artifact) async {
    if (artifact.bytes.length > maxArtifactBytes) {
      throw const PendingTextExportTooLargeException();
    }
    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(0x100000000)}';
    final database = await _getDatabase();
    await database.transaction((transaction) async {
      await _removeExpired(transaction);
      final records = await _store.find(transaction);
      var pendingBytes = 0;
      for (final record in records) {
        final text = record.value['text'];
        if (text is String) pendingBytes += utf8.encode(text).length;
      }
      if (records.length >= maxPendingEntries ||
          pendingBytes + artifact.bytes.length > maxPendingBytes) {
        throw const PendingTextExportStoreFullException();
      }
      await _store.record(id).put(transaction, {
        'fileName': artifact.fileName,
        'text': artifact.text,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
    return id;
  }

  Future<TextExportArtifact?> get(String id) async {
    final saved = await _store.record(id).get(await _getDatabase());
    if (saved == null) return null;
    final fileName = saved['fileName'];
    final text = saved['text'];
    if (fileName is! String || text is! String) return null;
    return TextExportArtifact(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(text)),
      text: text,
    );
  }

  Future<void> remove(String id) async {
    await _store.record(id).delete(await _getDatabase());
  }

  Future<void> _removeExpired(Transaction transaction) async {
    final expiration = DateTime.now()
        .subtract(maxPendingAge)
        .millisecondsSinceEpoch;
    final records = await _store.find(transaction);
    for (final record in records) {
      final createdAt = record.value['createdAt'];
      if (createdAt is! int || createdAt < expiration) {
        await _store.record(record.key).delete(transaction);
      }
    }
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) return;
    await (await database).close();
    _database = null;
  }

  Future<Database> _getDatabase() async {
    final databaseFuture = _database ??= Future.sync(_openDatabase);
    try {
      return await databaseFuture;
    } on Object {
      if (identical(_database, databaseFuture)) _database = null;
      rethrow;
    }
  }
}

final class PendingTextExportTooLargeException implements Exception {
  const PendingTextExportTooLargeException();
}

final class PendingTextExportStoreFullException implements Exception {
  const PendingTextExportStoreFullException();
}

final class TextExportShareTooLargeException implements Exception {
  const TextExportShareTooLargeException();
}
