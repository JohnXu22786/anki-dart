// Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from NotetypeJson.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonImageOcclusionPredicate', () {
    test('reads originalStockKind once per getter call', () {
      var reads = 0;
      final predicate = NotetypeJsonImageOcclusionPredicate(
        originalStockKind: () {
          reads++;
          return 17;
        },
        originalStockKindImageOcclusionValue: 17,
        isSourceJsonException: (_) => false,
      );

      expect(predicate.isImageOcclusion, isTrue);
      expect(reads, 1);
      expect(predicate.isImageOcclusion, isTrue);
      expect(reads, 2);
    });

    test('compares against the host image-occlusion value exactly', () {
      NotetypeJsonImageOcclusionPredicate predicate(int value) =>
          NotetypeJsonImageOcclusionPredicate(
            originalStockKind: () => value,
            originalStockKindImageOcclusionValue: 17,
            isSourceJsonException: (_) => false,
          );

      expect(predicate(17).isImageOcclusion, isTrue);
      expect(predicate(18).isImageOcclusion, isFalse);
    });

    test('returns false only for a host-identified JSON exception', () {
      final jsonException = _HostJsonException();
      final predicate = NotetypeJsonImageOcclusionPredicate(
        originalStockKind: () => throw jsonException,
        originalStockKindImageOcclusionValue: 17,
        isSourceJsonException: (error) => identical(error, jsonException),
      );

      expect(predicate.isImageOcclusion, isFalse);
    });

    test('propagates an unrelated exception unchanged', () {
      final exception = StateError('host failure');
      final predicate = NotetypeJsonImageOcclusionPredicate(
        originalStockKind: () => throw exception,
        originalStockKindImageOcclusionValue: 17,
        isSourceJsonException: (_) => false,
      );

      expect(() => predicate.isImageOcclusion, throwsA(same(exception)));
    });
  });
}

final class _HostJsonException implements Exception {}
