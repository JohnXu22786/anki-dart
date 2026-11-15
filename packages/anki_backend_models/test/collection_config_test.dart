// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('SchedulerVersion', () {
    test('uses the pinned repr(u8) values', () {
      expect(SchedulerVersion.v1.value, 1);
      expect(SchedulerVersion.v2.value, 2);
      expect(SchedulerVersion.fromRaw(1), SchedulerVersion.v1);
      expect(SchedulerVersion.fromRaw(2), SchedulerVersion.v2);
      expect(
        () => SchedulerVersion.fromRaw(0),
        throwsA(isA<InvalidModelValue>()),
      );
      expect(
        () => SchedulerVersion.fromRaw(255),
        throwsA(isA<InvalidModelValue>()),
      );
    });
  });

  group('CollectionConfigEntry', () {
    test('preserves stored key, bytes, mtime and signed 32-bit USN', () {
      final sourceBytes = [0, 128, 255];
      final entry = CollectionConfigEntry(
        key: 'schedVer',
        value: sourceBytes,
        usn: 0x100000001,
        mtime: Int64.parseInt('9007199254740993'),
      );
      sourceBytes[0] = 1;
      expect(entry.value, [0, 128, 255]);
      expect(entry.usn, 1);
      expect(entry.mtime, Int64.parseInt('9007199254740993'));
    });

    test('compares raw config entries by value', () {
      final entry = CollectionConfigEntry(
        key: 'curDeck',
        value: [1, 2, 3],
        usn: -1,
        mtime: Int64(4),
      );
      final same = CollectionConfigEntry(
        key: 'curDeck',
        value: [1, 2, 3],
        usn: -1,
        mtime: Int64(4),
      );
      expect(entry, same);
      expect(entry.hashCode, same.hashCode);
      expect(
        () => CollectionConfigEntry(
          key: 'bad',
          value: [256],
          usn: 0,
          mtime: Int64.ZERO,
        ),
        throwsArgumentError,
      );
    });
  });
}
